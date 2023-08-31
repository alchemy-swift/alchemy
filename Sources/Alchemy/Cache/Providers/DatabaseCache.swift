import Foundation
import NIO

/// A SQL based provider for `Cache`.
final class DatabaseCache: CacheProvider {
    private let db: Database
    
    /// Initialize this cache with a Database.
    ///
    /// - Parameter db: The database to cache with.
    init(_ db: Database = DB) {
        self.db = db
    }
    
    /// Get's the item, deleting it and returning nil if it's expired.
    private func getItem(key: String) async throws -> CacheItem? {
        let item = try await CacheItem.query(on: db).where("key" == key).first()
        guard let item = item else {
            return nil
        }
        
        guard item.isValid else {
            try await CacheItem.query(on: db).where("key" == key).delete()
            return nil
        }
        
        return item
    }
    
    // MARK: Cache
    
    func get<L: LosslessStringConvertible>(_ key: String) async throws -> L? {
        try await getItem(key: key)?.cast()
    }
    
    func set<L: LosslessStringConvertible>(_ key: String, value: L, for time: TimeAmount?) async throws {
        let item = try await getItem(key: key)
        let expiration = time.map { Date().adding(time: $0) }
        if var item = item {
            item.value = value.description
            item.expiration = expiration ?? -1
            _ = try await item.save(on: db)
        } else {
            _ = try await CacheItem(key: key, value: value.description, expiration: expiration ?? -1).save(on: db)
        }
    }
    
    func has(_ key: String) async throws -> Bool {
        try await getItem(key: key)?.isValid ?? false
    }
    
    func remove<L: LosslessStringConvertible>(_ key: String) async throws -> L? {
        guard let item = try await getItem(key: key) else {
            return nil
        }
        
        let value: L = try item.cast()
        _ = try await item.delete()
        return item.isValid ? value : nil
    }
    
    func delete(_ key: String) async throws {
        _ = try await CacheItem.query(on: db).where("key" == key).delete()
    }
    
    func increment(_ key: String, by amount: Int) async throws -> Int {
        if let item = try await getItem(key: key) {
            let newVal = try item.cast() + amount
            _ = try await item.update { $0.value = "\(newVal)" }
            return newVal
        }
        
        _ = try await CacheItem(key: key, value: "\(amount)").save(on: db)
        return amount
    }
    
    func decrement(_ key: String, by amount: Int) async throws -> Int {
        try await increment(key, by: -amount)
    }
    
    func wipe() async throws {
        try await CacheItem.truncate(on: db)
    }
}

extension Cache {
    /// Create a cache backed by an SQL database.
    ///
    /// - Parameter database: The database to drive your cache with.
    ///   Defaults to your default `Database`.
    /// - Returns: A cache.
    public static func database(_ database: Database = DB) -> Cache {
        Cache(provider: DatabaseCache(database))
    }
    
    /// Create a cache backed by the default SQL database.
    public static var database: Cache {
        .database()
    }
}

/// Model for storing cache data
private struct CacheItem: Model, Codable {
    static let table = "cache"

    var id: PK<Int> = .new
    let key: String
    var value: String
    var expiration: Int = -1
    
    var isValid: Bool {
        guard expiration >= 0 else {
            return true
        }

        return expiration > Int(Date().timeIntervalSince1970)
    }
    
    func cast<L: LosslessStringConvertible>(_ type: L.Type = L.self) throws -> L {
        guard let converted = L(value) else {
            throw CacheError("Unable to cast cache item `\(key)` to \(L.self).")
        }

        return converted
    }
}

extension Cache {
    /// Migration for adding a cache table to your database. Don't
    /// forget to apply this to your database before using a
    /// database backed cache.
    public struct AddCacheMigration: Alchemy.Migration {
        public init() {}
        
        public func up(db: Database) async throws {
            try await db.createTable("cache") {
                $0.increments("id").primary()
                $0.string("key").notNull().unique()
                $0.string("value", length: .unlimited).notNull()
                $0.int("expiration").notNull()
            }
        }
        
        public func down(db: Database) async throws {
            try await db.dropTable("cache")
        }
    }
}
