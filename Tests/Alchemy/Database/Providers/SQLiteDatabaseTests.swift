@testable
import Alchemy
import AlchemyTest
import SQLiteNIO

final class SQLiteDatabaseTests: TestCase<TestApp> {
    func testDatabase() async throws {
        let memory = Database.memory
        guard memory.provider as? Alchemy.SQLiteDatabaseProvider != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        let path = Database.sqlite(path: "foo")
        guard path.provider as? Alchemy.SQLiteDatabaseProvider != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        try await memory.shutdown()
        try await path.shutdown()
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
