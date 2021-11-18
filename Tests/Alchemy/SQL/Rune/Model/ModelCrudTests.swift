import AlchemyTest

final class ModelCrudTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.fake(migrations: [TestModelMigration(), TestModelCustomIdMigration()])
    }
    
    func testAll() async throws {
        let all = try await TestModel.all()
        XCTAssertEqual(all, [])
        
        try await TestModel.seed(5)
        
        let newAll = try await TestModel.all()
        XCTAssertEqual(newAll.count, 5)
    }
    
    func testSearch() async throws {
        let first = try await TestModel.first()
        XCTAssertEqual(first, nil)
        
        let model = try await TestModel(foo: "baz", bar: false).insertReturn()
        
        let findById = try await TestModel.find(model.getID())
        XCTAssertEqual(findById, model)
        
        do {
            _ = try await TestModel.find(999, or: TestError())
            XCTFail("`find(_:or:)` should throw on a missing element.")
        } catch {
            // do nothing
        }
        
        let missingId = try await TestModel.find(999)
        XCTAssertEqual(missingId, nil)
        
        let findByWhere = try await TestModel.find("foo" == "baz")
        XCTAssertEqual(findByWhere, model)
        
        let newFirst = try await TestModel.first()
        XCTAssertEqual(newFirst, model)
    }
    
    func testRandom() async throws {
        let random = try await TestModel.random()
        XCTAssertEqual(random, nil)
        
        try await TestModel.seed()
        
        let newRandom = try await TestModel.random()
        XCTAssertNotNil(newRandom)
    }
    
    func testDelete() async throws {
        let models = try await TestModel.seed(5)
        guard let first = models.first else {
            XCTFail("There should be 5 models in the database.")
            return
        }
        
        try await TestModel.delete(first.getID())
        
        let count = try await TestModel.all().count
        XCTAssertEqual(count, 4)
        
        try await TestModel.deleteAll()
        let newCount = try await TestModel.all().count
        XCTAssertEqual(newCount, 0)
    }
    
    func testInsertReturn() async throws {
        let model = try await TestModel(foo: "bar", bar: false).insertReturn()
        XCTAssertEqual(model.foo, "bar")
        XCTAssertEqual(model.bar, false)
        
        let customId = try await TestModelCustomId(foo: "bar").insertReturn()
        XCTAssertEqual(customId.foo, "bar")
    }
    
    func testUpdate() async throws {
        var model = try await TestModel.seed()
        model.foo = "baz"
        let pulled = try await TestModel.find(model.getID())
        XCTAssertNotEqual(pulled, model)
        _ = try await model.save()
        let newPulled = try await TestModel.find(model.getID())
        XCTAssertEqual(model, newPulled)
    }
    
    func testSync() async throws {
        let model = try await TestModel.seed()
        _ = try await model.update { $0.foo = "bar" }
        AssertNotEqual(model.foo, "bar")
        AssertEqual(try await model.sync().foo, "bar")
        
        do {
            let unsavedModel = TestModel(id: 12345, foo: "one", bar: false)
            _ = try await unsavedModel.sync()
            XCTFail("Syncing an unsaved model should throw")
        } catch {}
        
        do {
            let unsavedModel = TestModel(foo: "two", bar: true)
            _ = try await unsavedModel.sync()
            XCTFail("Syncing an unsaved model should throw")
        } catch {}
    }
}

private struct TestError: Error {}

private struct TestModelCustomId: Model {
    var id: UUID? = UUID()
    var foo: String
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

private struct TestModelCustomIdMigration: Migration {
    func up(schema: Schema) {
        schema.create(table: "test_model_custom_ids") {
            $0.uuid("id").primary()
            $0.string("foo").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "test_model_custom_ids")
    }
}