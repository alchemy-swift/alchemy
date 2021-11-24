import AlchemyTest

final class QueryCrudTests: TestCase<TestApp> {
    var db: Database!
    
    override func setUp() {
        super.setUp()
        db = Database.fake(migrations: [TestModelMigration()])
    }
    
    func testFind() async throws {
        AssertTrue(try await db.table("test_models").find("foo", equals: .string("bar")) == nil)
        try await TestModel(foo: "bar", bar: false).insert()
        AssertTrue(try await db.table("test_models").find("foo", equals: .string("bar")) != nil)
    }
    
    func testCount() async throws {
        AssertEqual(try await db.table("test_models").count(), 0)
        try await TestModel(foo: "bar", bar: false).insert()
        AssertEqual(try await db.table("test_models").count(), 1)
    }
}

private struct TestModel: Model, Seedable, Equatable {
    var id: Int?
    var foo: String
    var bar: Bool
    
    static func generate() async throws -> TestModel {
        TestModel(foo: faker.lorem.word(), bar: faker.number.randomBool())
    }
}

private struct TestModelMigration: Migration {
    func up(schema: Schema) {
        schema.create(table: "test_models") {
            $0.increments("id").primary()
            $0.string("foo").notNull()
            $0.bool("bar").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "test_models")
    }
}
