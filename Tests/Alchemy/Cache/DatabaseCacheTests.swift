import AlchemyTest

final class DatabaseCacheTests: TestCase<TestApp> {
    var cache: Cache {
        Cache.default
    }
    
    override func setUp() {
        super.setUp()
        Database.fake(migrations: [Cache.AddCacheMigration()])
        Cache.config(default: .database(.default))
    }
    
    func testSet() async throws {
        let value: String? = try await cache.get("foo")
        XCTAssertNil(value)
        
        try await cache.set("foo", value: "bar")
        
        let newValue: String? = try await cache.get("foo")
        XCTAssertEqual(newValue, "bar")
    }
    
    func testHas() async throws {
        let val = try await cache.has("foo")
        XCTAssertFalse(val)
        
        try await cache.set("foo", value: "bar")
        
        let newVal = try await cache.has("foo")
        XCTAssertTrue(newVal)
    }
    
    func testRemove() async throws {
        try await cache.set("foo", value: "bar")
        
        let removed: String? = try await cache.remove("foo")
        XCTAssertEqual(removed, "bar")
        
        let has = try await cache.has("foo")
        XCTAssertFalse(has)
    }
    
    func testDelete() async throws {
        try await cache.set("foo", value: "bar")
        try await cache.delete("foo")
        let has = try await cache.has("foo")
        XCTAssertFalse(has)
    }
    
    func testIncrement() async throws {
        let first = try await cache.increment("foo")
        XCTAssertEqual(first, 1)
        
        let second = try await cache.increment("foo", by: 10)
        XCTAssertEqual(second, 11)
        
        let third = try await cache.decrement("foo")
        XCTAssertEqual(third, 10)
        
        let fourth = try await cache.decrement("foo", by: 19)
        XCTAssertEqual(fourth, -9)
    }
    
    func testWipe() async throws {
        try await cache.set("foo", value: 1)
        try await cache.set("bar", value: 2)
        try await cache.set("baz", value: 3)
        
        try await cache.wipe()
        
        let foo: String? = try await cache.get("foo")
        let bar: String? = try await cache.get("bar")
        let baz: String? = try await cache.get("baz")
        
        XCTAssertNil(foo)
        XCTAssertNil(bar)
        XCTAssertNil(baz)
    }
}
