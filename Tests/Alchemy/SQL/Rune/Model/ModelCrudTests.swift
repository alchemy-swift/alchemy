import AlchemyTest

final class ModelCrudTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.fake(migrations: [TestModelMigration()])
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
        
        let model = try await TestModel(foo: "baz", bar: false).insert()
        
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
    
    func testUpdate() async throws {
        var model = try await TestModel.seed()
        model.foo = "baz"
        let pulled = try await TestModel.find(model.getID())
        XCTAssertNotEqual(pulled, model)
        _ = try await model.save()
        let newPulled = try await TestModel.find(model.getID())
        XCTAssertEqual(model, newPulled)
    }
}

private struct TestError: Error {}

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
