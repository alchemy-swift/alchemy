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
        let config = Store.Config(caches: [.default: .memory, 1: .memory, 2: .memory])
        Store.configure(using: config)
        XCTAssertNotNil(Store.resolveOptional(.default))
        XCTAssertNotNil(Store.resolveOptional(1))
        XCTAssertNotNil(Store.resolveOptional(2))
    }
    
    func testDatabaseCache() async throws {
        for test in allTests {
            Database.fake(migrations: [Store.AddCacheMigration()])
            Store.register(.database)
            try await test()
        }
    }
    
    func testMemoryCache() async throws {
        for test in allTests {
            Store.fake()
            try await test()
        }
    }
    
    func testRedisCache() async throws {
        for test in allTests {
            Redis.register(.testing)
            Store.register(.redis)
            
            guard await Redis.default.checkAvailable() else {
                throw XCTSkip()
            }
            
            try await test()
            try await Cache.wipe()
        }
    }
    
    private func _testSet() async throws {
        AssertNil(try await Cache.get("foo", as: String.self))
        try await Cache.set("foo", value: "bar")
        AssertEqual(try await Cache.get("foo"), "bar")
        try await Cache.set("foo", value: "baz")
        AssertEqual(try await Cache.get("foo"), "baz")
    }
    
    private func _testExpire() async throws {
        AssertNil(try await Cache.get("foo", as: String.self))
        try await Cache.set("foo", value: "bar", for: .zero)
        AssertNil(try await Cache.get("foo", as: String.self))
    }
    
    private func _testHas() async throws {
        AssertFalse(try await Cache.has("foo"))
        try await Cache.set("foo", value: "bar")
        AssertTrue(try await Cache.has("foo"))
    }
    
    private func _testRemove() async throws {
        try await Cache.set("foo", value: "bar")
        AssertEqual(try await Cache.remove("foo"), "bar")
        AssertFalse(try await Cache.has("foo"))
        AssertEqual(try await Cache.remove("foo", as: String.self), nil)
    }
    
    private func _testDelete() async throws {
        try await Cache.set("foo", value: "bar")
        try await Cache.delete("foo")
        AssertFalse(try await Cache.has("foo"))
    }
    
    private func _testIncrement() async throws {
        AssertEqual(try await Cache.increment("foo"), 1)
        AssertEqual(try await Cache.increment("foo", by: 10), 11)
        AssertEqual(try await Cache.decrement("foo"), 10)
        AssertEqual(try await Cache.decrement("foo", by: 19), -9)
    }
    
    private func _testWipe() async throws {
        try await Cache.set("foo", value: 1)
        try await Cache.set("bar", value: 2)
        try await Cache.set("baz", value: 3)
        try await Cache.wipe()
        AssertNil(try await Cache.get("foo", as: String.self))
        AssertNil(try await Cache.get("bar", as: String.self))
        AssertNil(try await Cache.get("baz", as: String.self))
    }
}
