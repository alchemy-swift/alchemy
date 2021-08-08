import Foundation
import NIO

/// A SQL based driver for `Cache`.
final class DatabaseCache: CacheDriver {
    private let db: Database
    
    /// Initialize this cache with a Database.
    ///
    /// - Parameter db: The database to cache with.
    init(_ db: Database = .default) {
        self.db = db
    }
    
    /// Get's the item, deleting it and returning nil if it's expired.
    private func getItem(key: String) -> EventLoopFuture<CacheItem?> {
        CacheItem.query(database: self.db)
            .where("_key" == key)
            .firstModel()
            .flatMap { item in
                guard let item = item else {
                    return .new(nil)
                }
                
                if item.isValid {
                    return .new(item)
                } else {
                    return CacheItem.query()
                        .where("_key" == key)
                        .delete()
                        .map { _ in nil }
                }
            }
    }
    
    // MARK: Cache
    
    func get<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
        self.getItem(key: key)
            .flatMapThrowing { try $0?.cast() }
    }
    
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) -> EventLoopFuture<Void> {
        self.getItem(key: key)
            .flatMap { item in
                let expiration = time.map { Date().adding(time: $0) }
                if var item = item {
                    item.text = value.stringValue
                    item.expiration = expiration ?? -1
                    return item.save(db: self.db)
                        .voided()
                } else {
                    return CacheItem(_key: key, text: value.stringValue, expiration: expiration ?? -1)
                        .save(db: self.db)
                        .voided()
                }
            }
    }
    
    func has(_ key: String) -> EventLoopFuture<Bool> {
        self.getItem(key: key)
            .map { $0?.isValid ?? false }
    }
    
    func remove<C: CacheAllowed>(_ key: String) -> EventLoopFuture<C?> {
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
    
    func delete(_ key: String) -> EventLoopFuture<Void> {
        CacheItem.query(database: self.db)
            .where("_key" == key)
            .delete()
            .voided()
    }
    
    func increment(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.getItem(key: key)
            .flatMap { item in
                if var item = item {
                    return catchError {
                        let value: Int = try item.cast()
                        let newVal = value + amount
                        item.text = "\(value + amount)"
                        return item.save().transform(to: newVal)
                    }
                } else {
                    return CacheItem(_key: key, text: "\(amount)")
                        .save(db: self.db)
                        .transform(to: amount)
                }
            }
    }
    
    func decrement(_ key: String, by amount: Int) -> EventLoopFuture<Int> {
        self.increment(key, by: -amount)
    }
    
    func wipe() -> EventLoopFuture<Void> {
        CacheItem.deleteAll(db: self.db)
    }
}

public extension Cache {
    static func database(_ database: Database = .default) -> Cache {
        Cache(DatabaseCache(database))
    }
}

private struct CacheItem: Model {
    static var tableName: String { "cache" }
    
    var id: Int?
    let _key: String
    var text: String
    var expiration: Int = -1
    
    var isValid: Bool {
        guard expiration >= 0 else {
            return true
        }
        
        return expiration > Int(Date().timeIntervalSince1970)
    }
    
    func validate() -> Self? {
        self.isValid ? self : nil
    }
    
    func cast<C: CacheAllowed>(_ type: C.Type = C.self) throws -> C {
        try C(self.text).unwrap(or: CacheError("Unable to cast cache item `\(self._key)` to \(C.self)."))
    }
}

extension Cache {
    public struct AddCacheMigration: Alchemy.Migration {
        public var name: String { "AddCacheMigration" }
        
        public init() {}
        
        public func up(schema: Schema) {
            schema.create(table: "cache") {
                $0.increments("id").primary()
                $0.string("_key").notNull().unique()
                $0.string("text", length: .unlimited).notNull()
                $0.int("expiration").notNull()
            }
        }
        
        public func down(schema: Schema) {
            schema.drop(table: "cache")
        }
    }
}
