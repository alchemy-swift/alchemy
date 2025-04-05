import AlchemyTesting

@Suite(.serialized)
struct ModelCrudTests {
    init() async throws {
        try await DB.shutdown()
        try await DB.fake(migrations: [TestModelMigration(), TestModelCustomIdMigration()])
    }

    @Test func all() async throws {
        let all = try await TestModel.all()
        #expect(all == [])

        try await TestModel.seed(5)
        
        let newAll = try await TestModel.all()
        #expect(newAll.count == 5)
    }
    
    @Test func search() async throws {
        let first = try await TestModel.first()
        #expect(first == nil)

        let model = try await TestModel(foo: "baz", bar: false).insertReturn()
        
        let findById = try await TestModel.find(model.id)
        #expect(findById == model)

        await #expect(throws: Error.self) {
            try await TestModel.require(999, error: TestError())
        }

        let missingId = try await TestModel.find(999)
        #expect(missingId == nil)

        let findByWhere = try await TestModel.firstWhere("foo" == "baz")
        #expect(findByWhere == model)

        let newFirst = try await TestModel.first()
        #expect(newFirst == model)
    }
    
    @Test func random() async throws {
        #expect(try await TestModel.random() == nil)
        try await TestModel.seed()
        #expect(try await TestModel.random() != nil)
    }
    
    @Test func delete() async throws {
        let models = try await TestModel.seed(5)
        guard let first = models.first else {
            XCTFail("There should be 5 models in the database.")
            return
        }
        
        try await TestModel.delete(first.id)
        
        let count = try await TestModel.all().count
        #expect(count == 4)

        try await TestModel.truncate()
        let newCount = try await TestModel.all().count
        #expect(newCount == 0)

        let model = try await TestModel.seed()
        try await TestModel.delete("foo" == model.foo)
        #expect(try await TestModel.all().isEmpty)

        let modelNew = try await TestModel.seed()
        try await TestModel.delete("foo" == modelNew.foo)
        #expect(try await TestModel.all().isEmpty)
    }
    
    @Test func deleteAll() async throws {
        let models = try await TestModel.seed(5)
        try await models.deleteAll()
        #expect(try await TestModel.all().isEmpty)
    }
    
    @Test func insertReturn() async throws {
        let model = try await TestModel(foo: "bar", bar: false).insertReturn()
        #expect(model.foo == "bar")
        #expect(!model.bar)

        let customId = try await TestModelCustomId(foo: "bar").insertReturn()
        #expect(customId.foo == "bar")
    }
    
    @Test func update() async throws {
        var model = try await TestModel.seed()
        let id = model.id
        model.foo = "baz"
        #expect(try await TestModel.find(id) != model)

        _ = try await model.save()
        #expect(try await TestModel.find(id) == model)

        _ = try await model.update(["foo": "foo"])
        #expect(try await TestModel.find(id)?.foo == "foo")
    }
    
    @Test func sync() async throws {
        let model = try await TestModel.seed()
        _ = try await model.update { $0.foo = "bar" }
        #expect(model.foo != "bar")
        #expect(try await model.refresh().foo == "bar")

        let unsavedModel = TestModel(foo: "one", bar: false)
        unsavedModel.id = 12345
        await #expect(throws: Error.self) {
            try await unsavedModel.refresh()
        }

        let unsavedModel2 = TestModel(foo: "two", bar: true)
        await #expect(throws: Error.self) {
            try await unsavedModel2.refresh()
        }
    }
}

private struct TestError: Error {}

@Model
private struct TestModelCustomId {
    var id = UUID()
    var foo: String
}

@Model
private struct TestModel: Seedable, Equatable {
    var id: Int
    var foo: String
    var bar: Bool
    
    static func generate() async throws -> TestModel {
        TestModel(foo: .random, bar: .random())
    }
}

private struct TestModelMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("test_models") {
            $0.increments("id").primary()
            $0.string("foo").notNull()
            $0.bool("bar").notNull()
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("test_models")
    }
}

private struct TestModelCustomIdMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("test_model_custom_ids") {
            $0.uuid("id").primary()
            $0.string("foo").notNull()
        }
    }
    
    func down(db: Database) async throws {
        try await db.dropTable("test_model_custom_ids")
    }
}
