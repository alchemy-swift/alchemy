@testable
import Alchemy
import AlchemyTesting
import SQLiteNIO

struct SQLiteDatabaseTests {
    @Test func database() async throws {
        let memory = Database.memory
        if memory.provider as? Alchemy.SQLiteDatabaseProvider == nil {
            Issue.record("The database provider should be SQLite.")
            return
        }

        let file = Database.sqlite(path: "foo")
        if file.provider as? Alchemy.SQLiteDatabaseProvider == nil {
            Issue.record("The database provider should be SQLite.")
            return
        }

        try await memory.shutdown()
        try await file.shutdown()
    }

    @Test func null() {
        #expect(SQLiteData(.null).sqlValue == .null)
    }

    @Test func string() {
        #expect(SQLiteData(.string("foo")).sqlValue == .string("foo"))
    }

    @Test func int() {
        #expect(SQLiteData(.int(1)).sqlValue == .int(1))
    }

    @Test func double() {
        #expect(SQLiteData(.double(2.0)).sqlValue == .double(2.0))
    }

    @Test func bool() {
        #expect(SQLiteData(.bool(false)).sqlValue == .int(0))
        #expect(SQLiteData(.bool(true)).sqlValue == .int(1))
    }

    @Test func json() {
        let jsonString = """
        {"foo":"one","bar":2}
        """
        let bytes = ByteBuffer(data: jsonString.data(using: .utf8) ?? Data())
        #expect(SQLiteData(.json(bytes)).sqlValue == .string(jsonString))
    }

    @Test func uuid() {
        let uuid = UUID()
        #expect(SQLiteData(.uuid(uuid)).sqlValue == .string(uuid.uuidString))
    }
}

