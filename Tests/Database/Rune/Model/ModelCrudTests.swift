import AlchemyTest

final class ModelCrudTests: TestCase<TestApp> {
    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake(migrations: [TestModelMigration(), TestModelCustomIdMigration()])
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
        
        let findById = try await TestModel.find(model.id)
        XCTAssertEqual(findById, model)
        
        do {
            _ = try await TestModel.require(999, error: TestError())
            XCTFail("`find(_:or:)` should throw on a missing element.")
        } catch {
            // do nothing
        }
        
        let missingId = try await TestModel.find(999)
        XCTAssertEqual(missingId, nil)
        
        let findByWhere = try await TestModel.firstWhere("foo" == "baz")
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
        
        try await TestModel.delete(first.id)
        
        let count = try await TestModel.all().count
        XCTAssertEqual(count, 4)
        
        try await TestModel.truncate()
        let newCount = try await TestModel.all().count
        XCTAssertEqual(newCount, 0)
        
        let model = try await TestModel.seed()
        try await TestModel.delete("foo" == model.foo)
        AssertEqual(try await TestModel.all().count, 0)
        
        let modelNew = try await TestModel.seed()
        try await TestModel.delete("foo" == modelNew.foo)
        AssertEqual(try await TestModel.all().count, 0)
    }
    
    func testDeleteAll() async throws {
        let models = try await TestModel.seed(5)
        try await models.deleteAll()
        AssertEqual(try await TestModel.all().count, 0)
    }
    
    func testInsertReturn() async throws {
        let model = try await TestModel(foo: "bar", bar: false).insertReturn()
        XCTAssertEqual(model.foo, "bar")
        XCTAssertEqual(model.bar, false)
        
        let customId = try await TestModelCustomId(foo: "bar").id(UUID()).insertReturn()
        XCTAssertEqual(customId.foo, "bar")
    }
    
    func testUpdate() async throws {
        var model = try await TestModel.seed()
        let id = model.id
        model.foo = "baz"
        AssertNotEqual(try await TestModel.find(id), model)
        
        _ = try await model.save()
        AssertEqual(try await TestModel.find(id), model)
        
        _ = try await model.update(["foo": "foo"])
        AssertEqual(try await TestModel.find(id)?.foo, "foo")
    }
    
    func testSync() async throws {
        let model = try await TestModel.seed()
        _ = try await model.update { $0.foo = "bar" }
        AssertNotEqual(model.foo, "bar")
        AssertEqual(try await model.refresh().foo, "bar")
        
        do {
            let unsavedModel = TestModel(foo: "one", bar: false)
            unsavedModel.id = 12345
            _ = try await unsavedModel.refresh()
            XCTFail("Syncing an unsaved model should throw")
        } catch {}
        
        do {
            let unsavedModel = TestModel(foo: "two", bar: true)
            _ = try await unsavedModel.refresh()
            XCTFail("Syncing an unsaved model should throw")
        } catch {}
    }
}

private struct TestError: Error {}

@Model
private struct TestModelCustomId {
    var id: UUID
    var foo: String
}

@Model
private struct TestModel: Seedable, Equatable {
    var id: Int
    var foo: String
    var bar: Bool
    
    static func generate() async throws -> TestModel {
        TestModel(foo: faker.lorem.word(), bar: faker.number.randomBool())
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
