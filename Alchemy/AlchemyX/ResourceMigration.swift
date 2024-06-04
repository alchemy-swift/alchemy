import AlchemyX
import Collections

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
            let columns = OrderedSet(try await db.columns(of: table))
            let adds = resourceSchema.keys.subtracting(columns)
            let drops = columns.subtracting(resourceSchema.keys)

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

extension Resource {
    fileprivate static var table: String {
        "\(Self.self)".lowercased().pluralized
    }

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
        let type = (type as? AnyOptional.Type)?.wrappedType ?? type
        if type == String.self {
            return .string(.unlimited)
        } else if type == Int.self {
            return name == "id" ? .increments : .bigInt
        } else if type == Double.self {
            return .double
        } else if type == Bool.self {
            return .bool
        } else if type == Date.self {
            return .date
        } else if type == UUID.self {
            return .uuid
        } else if type is Encodable.Type && type is Decodable.Type {
            return .json
        } else {
            preconditionFailure("unable to convert type \(type) to an SQL column type, try using a Codable type.")
        }
    }

    fileprivate var isOptional: Bool {
        (type as? AnyOptional.Type) != nil
    }
}

private protocol AnyOptional {
    static var wrappedType: Any.Type { get }
}

extension Optional: AnyOptional {
    static fileprivate var wrappedType: Any.Type {
        Wrapped.self
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
    fileprivate func columns(of table: String) async throws -> [String] {
        switch type {
        case .sqlite:
            try await raw("PRAGMA table_info(\(table))")
                .map { try $0.require("name").string() }
        case .postgres:
            try await self.table("information_schema.columns")
                .select("column_name", "data_type")
                .where("table_name" == table)
                .get()
                .map { try $0.require("column_name").string() }
        default:
            preconditionFailure("pulling schemas isn't supported on \(type.name) yet")
        }
    }
}
