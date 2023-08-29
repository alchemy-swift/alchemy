//import AlchemyTest
//
//final class QueryCrudTests: TestCase<TestApp> {
//    var db: Database!
//    
//    override func setUp() async throws {
//        try await super.setUp()
//        db = try await Database.fake(migrations: [TestModelMigration()])
//    }
//    
//    func testCount() async throws {
//        AssertEqual(try await db.table("test_models").count(), 0)
//        try await TestModel(foo: "bar", bar: false).insert()
//        AssertEqual(try await db.table("test_models").count(), 1)
//    }
//}
//
//private struct TestModel: Model, Seedable, Equatable {
//    var id: PK<Int> = .new
//    var foo: String
//    var bar: Bool
//    
//    static func generate() async throws -> TestModel {
//        TestModel(foo: faker.lorem.word(), bar: faker.number.randomBool())
//    }
//}
//
//private struct TestModelMigration: Migration {
//    func up(schema: Schema) {
//        schema.create(table: "test_models") {
//            $0.increments("id").primary()
//            $0.string("foo").notNull()
//            $0.bool("bar").notNull()
//        }
//    }
//    
//    func down(schema: Schema) {
//        schema.drop(table: "test_models")
//    }
//}
