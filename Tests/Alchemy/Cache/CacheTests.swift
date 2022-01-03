import AlchemyTest
import XCTest

final class CacheTests: TestCase<TestApp> {
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
        Cache.configure(with: config)
        XCTAssertNotNil(Container.resolve(Cache.self, identifier: Cache.Identifier.default))
        XCTAssertNotNil(Container.resolve(Cache.self, identifier: 1))
        XCTAssertNotNil(Container.resolve(Cache.self, identifier: 2))
    }
    
    func testDatabaseCache() async throws {
        for test in allTests {
            Database.fake(migrations: [Cache.AddCacheMigration()])
            Cache.bind(.database)
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
            RedisClient.bind(.testing)
            Cache.bind(.redis)
            
            guard await RedisClient.default.checkAvailable() else {
                throw XCTSkip()
            }
            
            try await test()
            try await Stash.wipe()
        }
    }
    
    private func _testSet() async throws {
        AssertNil(try await Stash.get("foo", as: String.self))
        try await Stash.set("foo", value: "bar")
        AssertEqual(try await Stash.get("foo"), "bar")
        try await Stash.set("foo", value: "baz")
        AssertEqual(try await Stash.get("foo"), "baz")
    }
    
    private func _testExpire() async throws {
        AssertNil(try await Stash.get("foo", as: String.self))
        try await Stash.set("foo", value: "bar", for: .zero)
        AssertNil(try await Stash.get("foo", as: String.self))
    }
    
    private func _testHas() async throws {
        AssertFalse(try await Stash.has("foo"))
        try await Stash.set("foo", value: "bar")
        AssertTrue(try await Stash.has("foo"))
    }
    
    private func _testRemove() async throws {
        try await Stash.set("foo", value: "bar")
        AssertEqual(try await Stash.remove("foo"), "bar")
        AssertFalse(try await Stash.has("foo"))
        AssertEqual(try await Stash.remove("foo", as: String.self), nil)
    }
    
    private func _testDelete() async throws {
        try await Stash.set("foo", value: "bar")
        try await Stash.delete("foo")
        AssertFalse(try await Stash.has("foo"))
    }
    
    private func _testIncrement() async throws {
        AssertEqual(try await Stash.increment("foo"), 1)
        AssertEqual(try await Stash.increment("foo", by: 10), 11)
        AssertEqual(try await Stash.decrement("foo"), 10)
        AssertEqual(try await Stash.decrement("foo", by: 19), -9)
    }
    
    private func _testWipe() async throws {
        try await Stash.set("foo", value: 1)
        try await Stash.set("bar", value: 2)
        try await Stash.set("baz", value: 3)
        try await Stash.wipe()
        AssertNil(try await Stash.get("foo", as: String.self))
        AssertNil(try await Stash.get("bar", as: String.self))
        AssertNil(try await Stash.get("baz", as: String.self))
    }
}
