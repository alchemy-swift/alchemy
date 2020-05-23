import Foundation
import NIO

public protocol Model: DatabaseCodable, RelationAllowed { }

public extension Model {
    static func query(database: Database = DB.default) -> ModelQuery<Self> {
        return ModelQuery<Self>(database: database).from(table: Self.tableName)
    }
}
