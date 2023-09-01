@testable
import Alchemy
import AlchemyTest

final class QueryTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testStartsEmpty() {
        let query = DB.table("foo")
        XCTAssertEqual(query.table, "foo")
        XCTAssertEqual(query.columns, ["*"])
        XCTAssertEqual(query.isDistinct, false)
        XCTAssertNil(query.limit)
        XCTAssertNil(query.offset)
        XCTAssertNil(query.lock)
        XCTAssertEqual(query.joins, [])
        XCTAssertEqual(query.wheres, [])
        XCTAssertEqual(query.groups, [])
        XCTAssertEqual(query.havings, [])
        XCTAssertEqual(query.orders, [])
    }

    func testTable() {
        XCTAssertEqual(DB.table("foo").table, "foo")
    }

    func testAlias() {
        XCTAssertEqual(DB.table("foo", as: "bar").table, "foo AS bar")
    }

    func testCount() async throws {
        try await Database.fake(migrations: [TestModel.Migration()])
        AssertEqual(try await DB.table("test_models").count(), 0)
        try await TestModel(foo: "bar", bar: false).insert()
        AssertEqual(try await DB.table("test_models").count(), 1)
    }
}

private struct TestModel: Model, Codable, Seedable, Equatable {
    var id: PK<Int> = .new
    var foo: String
    var bar: Bool

    static func generate() async throws -> TestModel {
        TestModel(foo: faker.lorem.word(), bar: faker.number.randomBool())
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
