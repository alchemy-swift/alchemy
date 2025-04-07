import AlchemyTesting

@Suite(.mockTestApp)
struct EagerLoadableTests {
    @Test func with() async throws {
        try await DB.fake(migrations: [TestModelMigration(), TestParentMigration()])
        try await TestParent.seed()
        let child = try await TestModel.seed()
        _ = try await child.testParent()
        let fetchedChild = try await TestModel.query().with(\.testParent).first()
        #expect(fetchedChild == child)
    }
}

private struct TestError: Error {}

@Model
private struct TestParent: Seedable, Equatable {
    var id: Int
    var baz: String

    static func generate() async throws -> TestParent {
        TestParent(baz: .random)
    }
}

@Model
private struct TestModel: Seedable, Equatable {
    var id: Int
    var foo: String
    var bar: Bool
    var testParentId: Int

    var testParent: BelongsTo<TestParent> {
        belongsTo()
    }

    static func generate() async throws -> TestModel {
        let parent: TestParent
        if let random = try await TestParent.random() {
            parent = random
        } else {
            parent = try await .seed()
        }
        
        return TestModel(foo: .random, bar: .random(), testParentId: parent.id)
    }
    
    static func == (lhs: TestModel, rhs: TestModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.foo == rhs.foo &&
        lhs.bar == rhs.bar &&
        lhs.testParent.force().id == rhs.testParent.force().id
    }
}

private struct TestParentMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("test_parents") {
            $0.increments("id").primary()
            $0.string("baz").notNull()
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("test_parents")
    }
}

private struct TestModelMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("test_models") {
            $0.increments("id").primary()
            $0.string("foo").notNull()
            $0.bool("bar").notNull()
            $0.bigInt("test_parent_id").references("id", on: "test_parents").notNull()
        }
    }
    
    func down(db: Database) async throws {
        try await db.dropTable("test_models")
    }
}
