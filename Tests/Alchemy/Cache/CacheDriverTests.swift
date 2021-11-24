import AlchemyTest
import XCTest

final class CacheDriverTests: TestCase<TestApp> {
    private var cache: Cache {
        Cache.default
    }
    
    private lazy var allTests = [
        _testSet,
        _testExpire,
        _testHas,
        _testRemove,
        _testDelete,
        _testIncrement,
        _testWipe,
    ]
    
    func testConfig() {
        let config = Cache.Config(caches: [.default: .memory, 1: .memory, 2: .memory])
        Cache.configure(using: config)
        XCTAssertNotNil(Cache.resolveOptional(.default))
        XCTAssertNotNil(Cache.resolveOptional(1))
        XCTAssertNotNil(Cache.resolveOptional(2))
    }
    
    func testDatabaseCache() async throws {
        for test in allTests {
            Database.fake(migrations: [Cache.AddCacheMigration()])
            Cache.register(.database)
            try await test()
        }
    }
    
    func testMemoryCache() async throws {
        for test in allTests {
            Cache.fake()
            try await test()
        }
    }
    
    func testRedisCache() async throws {
        for test in allTests {
            Redis.register(.testing)
            Cache.register(.redis)
            
            guard await Redis.default.checkAvailable() else {
                throw XCTSkip()
            }
            
            try await test()
            try await cache.wipe()
        }
    }
    
    private func _testSet() async throws {
        AssertNil(try await cache.get("foo", as: String.self))
        try await cache.set("foo", value: "bar")
        AssertEqual(try await cache.get("foo"), "bar")
        try await cache.set("foo", value: "baz")
        AssertEqual(try await cache.get("foo"), "baz")
    }
    
    private func _testExpire() async throws {
        AssertNil(try await cache.get("foo", as: String.self))
        try await cache.set("foo", value: "bar", for: .zero)
        AssertNil(try await cache.get("foo", as: String.self))
    }
    
    private func _testHas() async throws {
        AssertFalse(try await cache.has("foo"))
        try await cache.set("foo", value: "bar")
        AssertTrue(try await cache.has("foo"))
    }
    
    private func _testRemove() async throws {
        try await cache.set("foo", value: "bar")
        AssertEqual(try await cache.remove("foo"), "bar")
        AssertFalse(try await cache.has("foo"))
        AssertEqual(try await cache.remove("foo", as: String.self), nil)
    }
    
    private func _testDelete() async throws {
        try await cache.set("foo", value: "bar")
        try await cache.delete("foo")
        AssertFalse(try await cache.has("foo"))
    }
    
    private func _testIncrement() async throws {
        AssertEqual(try await cache.increment("foo"), 1)
        AssertEqual(try await cache.increment("foo", by: 10), 11)
        AssertEqual(try await cache.decrement("foo"), 10)
        AssertEqual(try await cache.decrement("foo", by: 19), -9)
    }
    
    private func _testWipe() async throws {
        try await cache.set("foo", value: 1)
        try await cache.set("bar", value: 2)
        try await cache.set("baz", value: 3)
        try await cache.wipe()
        AssertNil(try await cache.get("foo", as: String.self))
        AssertNil(try await cache.get("bar", as: String.self))
        AssertNil(try await cache.get("baz", as: String.self))
    }
}
