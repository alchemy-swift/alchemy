import Foundation
import NIO

struct DatabaseCacheMigration: Migration {
    fileprivate(set) static var table: String = "cache"
    
    func up(schema: Schema) {
        schema.create(table: DatabaseCacheMigration.table) {
            $0.increments("id").primary()
            $0.string("key").notNull().unique()
            $0.string("text", length: .unlimited).notNull()
            $0.int("expiration")
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: DatabaseCacheMigration.table)
    }
}

struct CacheItem: Model {
    static var tableName: String { DatabaseCacheMigration.table }
    
    var id: Int?
    let key: String
    var text: String
    var expiration: Int?
    
    var isValid: Bool {
        guard let expiration = expiration else {
            return true
        }
        
        return expiration > Int(Date().timeIntervalSince1970)
    }
    
    func validate() -> Self? {
        self.isValid ? self : nil
    }
    
    func cast<C: CacheAllowed>(_ type: C.Type = C.self) throws -> C {
        try C(self.text).unwrap(or: CacheError("Unable to convert cache item \(self.key) to \(C.self)."))
    }
}

public final class DatabaseCache: Cache {
    private let db: Database
    
    /// Initialize this cache with a Database.
    ///
    /// - Parameter db: The database to cache with.
    public init(_ db: Database = Services.db, tableName: String = "cache") {
        self.db = db
        DatabaseCacheMigration.table = tableName
    }
    
    private func getItem(key: String) -> EventLoopFuture<CacheItem?> {
        CacheItem.query(database: self.db)
            .where("key" == key)
            .firstModel()
    }
    
    public func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.getItem(key: key)
            .flatMapThrowing { try $0?.cast() }
    }
    
    public func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> {
        self.getItem(key: key)
            .flatMap { item in
                let expiration = time.map { Date().adding(time: $0) }
                if var item = item {
                    item.text = value.stringValue
                    item.expiration = expiration
                    return item.save(db: self.db)
                        .voided()
                } else {
                    return CacheItem(key: key, text: value.stringValue, expiration: expiration)
                        .save(db: self.db)
                        .voided()
                }
            }
    }
    
    public func has(_ key: String) -> EventLoopFuture<Bool> {
        self.getItem(key: key)
            .map { $0?.isValid ?? false }
    }
    
    public func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.getItem(key: key)
            .flatMap { item in
                catchError {
                    if let item = item {
                        let value: C = try item.cast()
                        return item
                            .delete()
                            .transform(to: item.isValid ? value : nil)
                    } else {
                        return .new(nil)
                    }
                }
            }
    }
    
    public func delete(_ key: String) -> EventLoopFuture<Void> {
        CacheItem.query(database: self.db)
            .where("key" == key)
            .delete()
            .voided()
    }
    
    public func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.getItem(key: key)
            .flatMap { item in
                if var item = item {
                    if item.isValid {
                        return catchError {
                            let value: Int = try item.cast()
                            let newVal = value + amount
                            item.text = "\(value + amount)"
                            return item.save().transform(to: newVal)
                        }
                    } else {
                        return item.delete()
                            .flatMap {
                                return CacheItem(key: key, text: "\(amount)")
                                    .save(db: self.db)
                                    .transform(to: amount)
                            }
                    }
                } else {
                    return CacheItem(key: key, text: "\(amount)")
                        .save(db: self.db)
                        .transform(to: amount)
                }
            }
    }
    
    public func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.increment(key, by: -amount)
    }
    
    public func wipe() -> EventLoopFuture<Void> {
        CacheItem.deleteAll(db: self.db)
    }
}
