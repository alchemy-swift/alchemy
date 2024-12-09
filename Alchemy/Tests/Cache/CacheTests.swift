import AlchemyTesting

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

    func testDatabaseCache() async throws {
        for test in allTests {
            try await DB.fake(migrations: [Cache.AddCacheMigration()])
            Container.main.set(Cache.database)
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
        Container.main.set(RedisClient.integration)
        Container.main.set(Cache.redis)

        guard await Redis.checkAvailable() else {
            throw XCTSkip()
        }

        for test in allTests {
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
