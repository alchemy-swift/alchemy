@testable
import Alchemy
import AlchemyTesting

struct QueryTests {
    @Test func startsEmpty() {
        let query = TestQuery("foo")
        #expect(query.table == "foo")
        #expect(query.columns == ["*"])
        #expect(query.isDistinct == false)
        #expect(query.limit == nil)
        #expect(query.offset == nil)
        #expect(query.lock == nil)
        #expect(query.joins == [])
        #expect(query.wheres == [])
        #expect(query.groups == [])
        #expect(query.havings == [])
        #expect(query.orders == [])
    }

    @Test func table() {
        #expect(TestQuery("foo").table == "foo")
    }

    @Test func alias() {
        let stub = Database.stub
        #expect(stub.table("foo", as: "bar").table == "foo AS bar")
    }

    @Test func count() async throws {
        let db = Database.memory
        try await db.migrate([TestModel.Migration()])
        #expect(try await db.table("test_models").count() == 0)
        try await TestModel(foo: "bar", bar: false).insert(on: db)
        #expect(try await db.table("test_models").count() == 1)
        try await db.shutdown()
    }
}

@Model
private struct TestModel: Seedable, Equatable {
    var id: Int
    var foo: String
    var bar: Bool

    static func generate() async throws -> TestModel {
        TestModel(foo: .random, bar: .random())
    }

    struct Migration: Alchemy.Migration {
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
}
