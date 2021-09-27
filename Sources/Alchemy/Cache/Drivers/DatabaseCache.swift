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
    private func getItem(key: String) async throws -> CacheItem? {
        let item = try await CacheItem.query(database: db).where("_key" == key).firstModel()
        guard let item = item else {
            return nil
        }
        
        if item.isValid {
            return item
        } else {
            _ = try await CacheItem.query(database: db).where("_key" == key).delete()
            return nil
        }
    }
    
    // MARK: Cache
    
    func get<C: CacheAllowed>(_ key: String) async throws -> C? {
        try await getItem(key: key)?.cast()
    }
    
    func set<C: CacheAllowed>(_ key: String, value: C, for time: TimeAmount?) async throws {
        let item = try await getItem(key: key)
        let expiration = time.map { Date().adding(time: $0) }
        if var item = item {
            item.text = value.stringValue
            item.expiration = expiration ?? -1
            _ = try await item.save(db: db)
        } else {
            _ = try await CacheItem(_key: key, text: value.stringValue, expiration: expiration ?? -1).save(db: db)
        }
    }
    
    func has(_ key: String) async throws -> Bool {
        try await getItem(key: key)?.isValid ?? false
    }
    
    func remove<C: CacheAllowed>(_ key: String) async throws -> C? {
        if let item = try await getItem(key: key) {
            let value: C = try item.cast()
            _ = try await item.delete()
            return item.isValid ? value : nil
        } else {
            return nil
        }
    }
    
    func delete(_ key: String) async throws {
        _ = try await CacheItem.query(database: db).where("_key" == key).delete()
    }
    
    func increment(_ key: String, by amount: Int) async throws -> Int {
        if let item = try await getItem(key: key) {
            let newVal = try item.cast() + amount
            _ = try await item.update { $0.text = "\(newVal)" }
            return newVal
        } else {
            _ = try await CacheItem(_key: key, text: "\(amount)").save(db: db)
            return amount
        }
    }
    
    func decrement(_ key: String, by amount: Int) async throws -> Int {
        try await increment(key, by: -amount)
    }
    
    func wipe() async throws {
        try await CacheItem.deleteAll(db: db)
    }
}

extension Cache {
    /// Create a cache backed by an SQL database.
    ///
    /// - Parameter database: The database to drive your cache with.
    ///   Defaults to your default `Database`.
    /// - Returns: A cache.
    public static func database(_ database: Database = .default) -> Cache {
        Cache(DatabaseCache(database))
    }
}

/// Model for storing cache data
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
    /// Migration for adding a cache table to your database. Don't
    /// forget to apply this to your database before using a
    /// database backed cache.
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
