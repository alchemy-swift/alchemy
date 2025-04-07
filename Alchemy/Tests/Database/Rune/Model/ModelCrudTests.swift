import AlchemyTesting
import Foundation

struct ModelCrudTests {
    let db: Database

    init() async throws {
        let db = Database.memory
        try await db.migrate([TestModelMigration(), TestModelCustomIdMigration()])
        self.db = db
    }

    @Test func all() async throws {
        let all = try await TestModel.all(on: db)
        #expect(all == [])

        try await TestModel.seed(on: db, 5)

        let newAll = try await TestModel.all(on: db)
        #expect(newAll.count == 5)

        try await _cleanup()
    }
    
    @Test func search() async throws {
        let first = try await TestModel.first(db: db)
        #expect(first == nil)

        let model = try await TestModel(foo: "baz", bar: false).insertReturn(on: db)

        let findById = try await TestModel.find(on: db, model.id)
        #expect(findById == model)

        await #expect(throws: Error.self) {
            try await TestModel.require(999, error: TestError(), db: db)
        }

        let missingId = try await TestModel.find(on: db, 999)
        #expect(missingId == nil)

        let findByWhere = try await TestModel.firstWhere(on: db, "foo" == "baz")
        #expect(findByWhere == model)

        let newFirst = try await TestModel.first(db: db)
        #expect(newFirst == model)

        try await _cleanup()
    }
    
    @Test func random() async throws {
        #expect(try await TestModel.random(on: db) == nil)
        try await TestModel.seed(on: db)
        #expect(try await TestModel.random(on: db) != nil)

        try await _cleanup()
    }
    
    @Test func delete() async throws {
        let models = try await TestModel.seed(on: db, 5)
        guard let first = models.first else {
            Issue.record("There should be 5 models in the database.")
            return
        }
        
        try await TestModel.delete(on: db, first.id)
        
        let count = try await TestModel.all(on: db).count
        #expect(count == 4)

        try await TestModel.truncate(on: db)
        let newCount = try await TestModel.all(on: db).count
        #expect(newCount == 0)

        let model = try await TestModel.seed(on: db)
        try await TestModel.delete(on: db, "foo" == model.foo)
        #expect(try await TestModel.all(on: db).isEmpty)

        let modelNew = try await TestModel.seed(on: db)
        try await TestModel.delete(on: db, "foo" == modelNew.foo)
        #expect(try await TestModel.all(on: db).isEmpty)

        try await _cleanup()
    }
    
    @Test func deleteAll() async throws {
        let models = try await TestModel.seed(on: db, 5)
        try await models.deleteAll(on: db)
        #expect(try await TestModel.all(on: db).isEmpty)

        try await _cleanup()
    }
    
    @Test func insertReturn() async throws {
        let model = try await TestModel(foo: "bar", bar: false).insertReturn(on: db)
        #expect(model.foo == "bar")
        #expect(!model.bar)

        let customId = try await TestModelCustomId(foo: "bar").insertReturn(on: db)
        #expect(customId.foo == "bar")

        try await _cleanup()
    }
    
    @Test func update() async throws {
        var model = try await TestModel.seed(on: db)
        let id = model.id
        model.foo = "baz"
        #expect(try await TestModel.find(on: db, id) != model)

        _ = try await model.save(on: db)
        #expect(try await TestModel.find(on: db, id) == model)

        _ = try await model.update(on: db, ["foo": "foo"])
        #expect(try await TestModel.find(on: db, id)?.foo == "foo")

        try await _cleanup()
    }
    
    @Test func sync() async throws {
        let model = try await TestModel.seed(on: db)
        _ = try await model.update(on: db) { $0.foo = "bar" }
        #expect(model.foo != "bar")
        #expect(try await model.refresh(on: db).foo == "bar")

        let unsavedModel = TestModel(foo: "one", bar: false)
        unsavedModel.id = 12345
        await #expect(throws: Error.self) {
            try await unsavedModel.refresh(on: db)
        }

        let unsavedModel2 = TestModel(foo: "two", bar: true)
        await #expect(throws: Error.self) {
            try await unsavedModel2.refresh(on: db)
        }

        try await _cleanup()
    }

    private func _cleanup() async throws {
        try await db.shutdown()
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
