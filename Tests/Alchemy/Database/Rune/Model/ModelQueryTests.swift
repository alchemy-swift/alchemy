//import AlchemyTest
//
//final class ModelQueryTests: TestCase<TestApp> {
//    override func setUp() async throws {
//        try await super.setUp()
//        try await Database.fake(migrations: [
//            TestModelMigration(),
//            TestParentMigration()
//        ])
//    }
//    
//    func testWith() async throws {
//        try await TestParent.seed()
//        let child = try await TestModel.seed()
//        let fetchedChild = try await TestModel.query().with(\.testParent).first()
//        XCTAssertEqual(fetchedChild, child)
//    }
//}
//
//private struct TestError: Error {}
//
//private struct TestParent: Model, Seedable, Equatable {
//    var id: PK<Int> = .new
//    var baz: String
//
//    static func generate() async throws -> TestParent {
//        TestParent(baz: faker.lorem.word())
//    }
//}
//
//private struct TestModel: Model, Seedable, Equatable {
//    var id: PK<Int> = .new
//    var foo: String
//    var bar: Bool
//    var testParentId: Int
//
//    var testParent: BelongsTo<TestParent> {
//        belongsTo()
//    }
//
//    static func generate() async throws -> TestModel {
//        let parent: TestParent
//        if let random = try await TestParent.random() {
//            parent = random
//        } else {
//            parent = try await .seed()
//        }
//        
//        return TestModel(foo: faker.lorem.word(), bar: faker.number.randomBool(), testParentId: try parent.id.require())
//    }
//    
//    static func == (lhs: TestModel, rhs: TestModel) -> Bool {
//        lhs.id == rhs.id &&
//        lhs.foo == rhs.foo &&
//        lhs.bar == rhs.bar &&
//        lhs.testParent.force().id == rhs.testParent.force().id
//    }
//}
//
//private struct TestParentMigration: Migration {
//    func up(schema: Schema) {
//        schema.create(table: "test_parents") {
//            $0.increments("id").primary()
//            $0.string("baz").notNull()
//        }
//    }
//    
//    func down(schema: Schema) {
//        schema.drop(table: "test_parents")
//    }
//}
//
//private struct TestModelMigration: Migration {
//    func up(schema: Schema) {
//        schema.create(table: "test_models") {
//            $0.increments("id").primary()
//            $0.string("foo").notNull()
//            $0.bool("bar").notNull()
//            $0.bigInt("test_parent_id").references("id", on: "test_parents").notNull()
//        }
//    }
//    
//    func down(schema: Schema) {
//        schema.drop(table: "test_models")
//    }
//}
