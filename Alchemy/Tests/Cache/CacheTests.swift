import AlchemyTesting

@Suite(.mockContainer)
struct CacheTests: TestSuite {
    @Test(arguments: Provider.allCases)
    func set(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        #expect(try await Stash.get("foo", as: String.self) == nil)
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.get("foo") == "bar")
        try await Stash.set("foo", value: "baz")
        #expect(try await Stash.get("foo") == "baz")
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func expire(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        #expect(try await Stash.get("foo", as: String.self) == nil)
        try await Stash.set("foo", value: "bar", for: .zero)
        #expect(try await Stash.get("foo", as: String.self) == nil)
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func has(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        #expect(try await !Stash.has("foo"))
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.has("foo"))
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func remove(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        try await Stash.set("foo", value: "bar")
        #expect(try await Stash.remove("foo") == "bar")
        #expect(try await !Stash.has("foo"))
        #expect(try await Stash.remove("foo", as: String.self) == nil)
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func delete(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        try await Stash.set("foo", value: "bar")
        try await Stash.delete("foo")
        #expect(try await !Stash.has("foo"))
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func increment(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        #expect(try await Stash.increment("foo") == 1)
        #expect(try await Stash.increment("foo", by: 10) == 11)
        #expect(try await Stash.decrement("foo") == 10)
        #expect(try await Stash.decrement("foo", by: 19) == -9)
        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func wipe(provider: Provider) async throws {
        guard try await provider.setup() else { return }
        try await Stash.set("foo", value: 1)
        try await Stash.set("bar", value: 2)
        try await Stash.set("baz", value: 3)
        try await Stash.wipe()
        #expect(try await Stash.get("foo", as: String.self) == nil)
        #expect(try await Stash.get("bar", as: String.self) == nil)
        #expect(try await Stash.get("baz", as: String.self) == nil)
        try await provider.teardown()
    }
}

extension CacheTests {
    enum Provider: CaseIterable {
        case memory
        case database
        case redis

        func setup() async throws -> Bool {
            switch self {
            case .database:
                try await DB.fake(migrations: [Cache.AddCacheMigration()])
                Container.main.set(Cache.database)
            case .memory:
                Cache.fake()
            case .redis:
                Container.main.set(RedisClient.integration)
                Container.main.set(Cache.redis)
                guard await Redis.checkAvailable() else { return false }
            }

            return true
        }

        func teardown() async throws {
            guard case .redis = self else { return }
            _ = try await Redis.send(command: "FLUSHDB").get()
        }
    }
}
