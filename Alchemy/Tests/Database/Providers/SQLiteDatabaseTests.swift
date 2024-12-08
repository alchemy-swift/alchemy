@testable
import Alchemy
import AlchemyTesting
import SQLiteNIO

final class SQLiteDatabaseTests: TestCase<TestApp> {
    func testDatabase() async throws {
        if Database.memory.provider as? Alchemy.SQLiteDatabaseProvider == nil {
            XCTFail("The database provider should be SQLite.")
        }
        
        if Database.sqlite(path: "foo").provider as? Alchemy.SQLiteDatabaseProvider == nil {
            XCTFail("The database provider should be SQLite.")
        }
    }

    func testNull() {
        XCTAssertEqual(SQLiteData(.null).sqlValue, .null)
    }

    func testString() {
        XCTAssertEqual(SQLiteData(.string("foo")).sqlValue, .string("foo"))
    }

    func testInt() {
        XCTAssertEqual(SQLiteData(.int(1)).sqlValue, .int(1))
    }

    func testDouble() {
        XCTAssertEqual(SQLiteData(.double(2.0)).sqlValue, .double(2.0))
    }

    func testBool() {
        XCTAssertEqual(SQLiteData(.bool(false)).sqlValue, .int(0))
        XCTAssertEqual(SQLiteData(.bool(true)).sqlValue, .int(1))
    }

    func testJson() {
        let jsonString = """
        {"foo":"one","bar":2}
        """
        let bytes = ByteBuffer(data: jsonString.data(using: .utf8) ?? Data())
        XCTAssertEqual(SQLiteData(.json(bytes)).sqlValue, .string(jsonString))
    }

    func testUuid() {
        let uuid = UUID()
        XCTAssertEqual(SQLiteData(.uuid(uuid)).sqlValue, .string(uuid.uuidString))
    }
}
