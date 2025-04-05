import AlchemyTesting

struct CacheTests: AppSuite {
    let app = TestApp()

    private var allTests: [() async throws -> Void] {
        [
            _testSet,
            _testExpire,
            _testHas,
            _testRemove,
            _testDelete,
            _testIncrement,
            _testWipe,
        ]
    }

    @Test func databaseCache() async throws {
        for test in allTests {
            try await withApp { app in
                try await DB.fake(migrations: [Cache.AddCacheMigration()])
                Container.main.set(Cache.database)
                try await test()
            }
        }
    }
    
    @Test func memoryCache() async throws {
        for test in allTests {
            try await withApp { app in
                Cache.fake()
                try await test()
            }
        }
    }
    
    @Test func redisCache() async throws {
        Container.main.set(RedisClient.integration)
        Container.main.set(Cache.redis)

        guard await Redis.checkAvailable() else {
            // no option to skip based on async logic in swift-testing
            return
        }

        for test in allTests {
            try await withApp { app in
                try await test()
                try await Stash.wipe()
            }
        }
    }
    
    private func _testSet() async throws {
        #expect(try await Stash.get("foo", as: String.self) == nil)
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.get("foo") == "bar")
        try await Stash.set("foo", value: "baz")
        #expect(try await Stash.get("foo") == "baz")
    }
    
    private func _testExpire() async throws {
        #expect(try await Stash.get("foo", as: String.self) == nil)
        try await Stash.set("foo", value: "bar", for: .zero)
        #expect(try await Stash.get("foo", as: String.self) == nil)
    }
    
    private func _testHas() async throws {
        #expect(try await !Stash.has("foo"))
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.has("foo"))
    }
    
    private func _testRemove() async throws {
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.remove("foo") == "bar")
        #expect(try await !Stash.has("foo"))
        #expect(try await Stash.remove("foo", as: String.self) == nil)
    }
    
    private func _testDelete() async throws {
        try await Stash.set("foo", value: "bar")
        try await Stash.delete("foo")
        #expect(try await !Stash.has("foo"))
    }
    
    private func _testIncrement() async throws {
        #expect(try await Stash.increment("foo") == 1)
        #expect(try await Stash.increment("foo", by: 10) == 11)
        #expect(try await Stash.decrement("foo") == 10)
        #expect(try await Stash.decrement("foo", by: 19) == -9)
    }
    
    private func _testWipe() async throws {
        try await Stash.set("foo", value: 1)
        try await Stash.set("bar", value: 2)
        try await Stash.set("baz", value: 3)
        try await Stash.wipe()
        #expect(try await Stash.get("foo", as: String.self) == nil)
        #expect(try await Stash.get("bar", as: String.self) == nil)
        #expect(try await Stash.get("baz", as: String.self) == nil)
    }
}
