import AlchemyX
import Collections

extension Resource {
    static var table: String {
        "\(Self.self)".lowercased().pluralized
    }
}

public struct ResourceMigration<R: Resource>: Migration {
    public var name: String {
        let type = KeyMapping.snakeCase.encode("\(R.self)")
        return "resource_migration_\(type)" + "_\(Int(Date().timeIntervalSince1970))"
    }

    public init() {}

    public func up(db: Database) async throws {
        let table = db.keyMapping.encode(R.table)
        let resourceSchema = R.schema(keyMapping: db.keyMapping)
        if try await db.hasTable(table) {

            // add new and drop old keys
            let tableSchema = try await db.schema(for: table)
            let adds = resourceSchema.keys.subtracting(tableSchema.keys)
            let drops = tableSchema.keys.subtracting(resourceSchema.keys)

            Log.info("Adding \(adds) and dropping \(drops) from Resource \(R.self)")

            try await db.alterTable(table) {
                for add in adds {
                    if let field = resourceSchema[add] {
                        $0.column(add, field: field)
                    }
                }

                for drop in drops {
                    $0.drop(column: drop)
                }
            }
        } else {

            Log.info("Creating table \(table)")

            // create the table from scratch
            try await db.createTable(table) {
                for (column, field) in resourceSchema {
                    $0.column(column, field: field)
                }
            }
        }
    }

    public func down(db: Database) async throws {
        // ignore
    }
}

extension CreateColumnBuilder {
    @discardableResult func `default`(any: Any?) -> Self {
        guard let any else { return self }
        guard let value = any as? Default else { return self }
        return `default`(val: value)
    }
}

extension CreateTableBuilder {
    fileprivate func column(_ name: String, field: ResourceField) {
        switch field.columnType() {
        case .increments: 
            increments(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .int:
            int(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .bigInt:
            bigInt(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .double:
            double(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .string(let length):
            string(name, length: length)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .uuid:
            uuid(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .bool:
            bool(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .date:
            date(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        case .json:
            json(name)
                .notNull(if: !field.isOptional)
                .primary(if: name == "id")
                .default(any: field.default)
        }
    }
}

extension CreateColumnBuilder {
    @discardableResult fileprivate func notNull(if value: Bool) -> Self {
        value ? notNull() : self
    }

    @discardableResult fileprivate func primary(if value: Bool) -> Self {
        value ? primary() : self
    }
}

extension Database {
    fileprivate func schema(for table: String) async throws -> OrderedDictionary<String, SQLiteType> {
        let rows = try await raw("PRAGMA table_info(\(table))")
        return OrderedDictionary(
            try rows.map {
                let name = try $0.require("name").string()
                let typeString = try $0.require("type").string()
                guard let type = SQLiteType.parse(typeString) else {
                    throw DatabaseError("Unable to decode SQLite type \(typeString)")
                }

                return (name, type)
            },
            uniquingKeysWith: { a, _ in a }
        )
    }

    enum SQLiteType: String {
        case null = "NULL"
        case integer = "INTEGER"
        case real = "REAL"
        case text = "TEXT"
        case blob = "BLOB"
        case numeric = "NUMERIC"

        static func parse(_ sqliteType: String) -> SQLiteType? {
            switch sqliteType.lowercased() {
            case "double": .real
            case "bigint": .integer
            case "blob": .blob
            case "datetime": .numeric
            case "int": .integer
            case "integer": .integer
            case "text": .text
            case "varchar": .text
            case "null": .null
            case "real": .real
            case "numeric": .numeric
            default: nil
            }
        }
    }
}

extension Resource {
    fileprivate static func schema(keyMapping: KeyMapping) -> OrderedDictionary<String, ResourceField> {
        OrderedDictionary(
            fields.map { _, field in
                (keyMapping.encode(field.name), field)
            },
            uniquingKeysWith: { a, _ in a }
        )
    }
}

extension ResourceField {
    fileprivate func columnType() -> ColumnType {
        if type == String.self {
            .string(.unlimited)
        } else if type == Int.self {
            name == "id" ? .increments : .bigInt
        } else if type == Double.self {
            .double
        } else if type == Bool.self {
            .bool
        } else if type == Date.self {
            .date
        } else if type == UUID.self {
            .uuid
        } else if type is Encodable.Type && type is Decodable.Type {
            .json
        } else {
            preconditionFailure("unable to convert type \(type) to an SQL column type, try using a Codable type")
        }
    }
}
