import Alchemy

struct Context<M> {
    let database: Database
    let row: SQLRow?
    var relationCache: [String: Any]

    static var new: Context<M> {
        .init(database: DB, row: nil, relationCache: [:])
    }

    static func row(_ row: SQLRow) -> Context<M> {
        .init(database: DB, row: row, relationCache: [:])
    }
}

/*
 A Model has
 1. A context, describing the row and database it came from as well as eager loaded relationships.
 2. A mapping of keyPaths to column names of stored properties.
 3. An initializer that creates the model given an `SQLRow`.
 4. A function that generates an SQLRow to be saved to the database.
 */

final class User2 {
    var id: Int?
    let name: String
    let age: Int
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date

    // MARK: Generated

    let context: Context<User2>

    init(context: Context<User2> = .new, id: Int? = nil, name: String, age: Int, createdAt: Date, updatedAt: Date, deletedAt: Date) {
        self.context = context
        self.id = id
        self.name = name
        self.age = age
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(row: SQLRow) throws {
        self.context = .new
        let props = Self.storedProperties
        self.id = try row.require(props[\.id]!).int()
        self.name = try row.require(props[\.name]!).string()
        self.age = try row.require(props[\.age]!).int()
        self.createdAt = try row.require(props[\.createdAt]!).date()
        self.updatedAt = try row.require(props[\.updatedAt]!).date()
        self.deletedAt = try row.require(props[\.deletedAt]!).date()
    }

    func fields() -> [String: SQLConvertible] {
        var fields: [String: SQLConvertible] = [:]
        for (kp, column) in User2.storedProperties {
            if let value = self[keyPath: kp] as? SQLConvertible {
                fields[column] = value
            }
        }

        return fields
    }

    static let storedProperties: [PartialKeyPath<User2>: String] = [
        \.id: "id",
        \.name: "name",
        \.age: "age",
        \.createdAt: "createdAt",
        \.updatedAt: "updatedAt",
        \.deletedAt: "deletedAt",
    ]
}
