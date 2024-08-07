import AlchemyX
import Collections
import Foundation

extension Database {
    /// Adds or alters a database table to match the schema of the Resource.
    func updateSchema(_ resource: (some Resource).Type) async throws {
        let table = keyMapping.encode(resource.table)
        let resourceSchema = resource.schema(keyMapping: keyMapping)
        if try await hasTable(table) {
            let columns = OrderedSet(try await columns(of: table))
            let adds = resourceSchema.keys.subtracting(columns)
            let drops = type == .sqlite ? [] : columns.subtracting(resourceSchema.keys)

            guard !adds.isEmpty || !drops.isEmpty else {
                Log.info("Resource '\(resource)' is up to date.".green)
                return
            }

            if !adds.isEmpty {
                Log.info("Adding \(adds.commaJoined) to resource '\(resource)'...")
            }

            if !drops.isEmpty {
                Log.info("Dropping \(drops.commaJoined) from '\(resource)'...")
            }

            try await alterTable(table) {
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
            try await createTable(table) {
                for (column, field) in resourceSchema {
                    $0.column(column, field: field)
                }
            }
        }
    }
}

extension Resource {
    fileprivate static var table: String {
        "\(Self.self)".lowercased().pluralized
    }

    fileprivate static func schema(keyMapping: KeyMapping) -> OrderedDictionary<String, ResourceField> {
        OrderedDictionary(
            (fields.values + [.userId])
                .map { (keyMapping.encode($0.name), $0) },
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

    fileprivate static var userId: ResourceField {
        .init("userId", type: UUID.self)
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
