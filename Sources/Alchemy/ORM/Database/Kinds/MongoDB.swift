/// This isn't working, just an example of adding a custom db.

/// Add a Database class with `Kind` as the kind type above.
public final class MongoDatabase: Database {
    // Can optionally override any function such as setup, query, etc.
}

/// Then, potentially write a custom query builder for a `MongoDB` database.
/// (assuming general query builder looks something like this)
//protocol QueryBuilder {
//    associatedtype Kind
//    func toString() -> String
//}
//
//struct MongoBuilder: QueryBuilder {
//    // Assuming QueryBuilder has associated type `Kind`
//    public typealias Kind = MongoDB
//    
//    func toString() -> String {
//        "db.collectionname.find( {} )"
//    }
//}
