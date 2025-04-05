@testable
import Alchemy
import AlchemyTesting
import MySQLNIO
import NIOSSL

struct MySQLDatabaseTests {
    @Test func database() async throws {
        let db = Database.mysql(host: "127.0.0.1", database: "foo", username: "bar", password: "baz")
        guard let provider = db.provider as? Alchemy.MySQLDatabaseProvider else {
            Issue.record("The database provider should be MySQL.")
            return
        }

        #expect(try provider.pool.source.address().ipAddress == "127.0.0.1")
        #expect(try provider.pool.source.address().port == 3306)
        #expect(provider.pool.source.database == "foo")
        #expect(provider.pool.source.username == "bar")
        #expect(provider.pool.source.password == "baz")
        try await db.shutdown()
    }

    @Test func nilValue() {
        #expect(MySQLData(.null).sqlValue == .null)
    }

    @Test func string() {
        #expect(MySQLData(.string("foo")).sqlValue == .string("foo"))
        #expect(MySQLData(type: .string, buffer: nil).sqlValue == .null)
    }

    @Test func int() {
        #expect(MySQLData(.int(1)).sqlValue == .int(1))
        #expect(MySQLData(type: .long, buffer: nil).sqlValue == .null)
    }

    @Test func double() {
        #expect(MySQLData(.double(2.0)).sqlValue == .double(2.0))
        #expect(MySQLData(type: .float, buffer: nil).sqlValue == .null)
    }

    @Test func bool() {
        #expect(MySQLData(.bool(false)).sqlValue == .bool(false))
        #expect(MySQLData(type: .tiny, buffer: nil).sqlValue == .null)
    }

    @Test func date() throws {
        let date = Date()
        // MySQLNIO occasionally loses some millisecond precision; round off.
        let roundedDate = Date(timeIntervalSince1970: TimeInterval((Int(date.timeIntervalSince1970) / 1000) * 1000))
        #expect(MySQLData(.date(roundedDate)).sqlValue == .date(roundedDate))
        #expect(MySQLData(type: .date, buffer: nil).sqlValue == .null)
    }

    @Test func json() {
        #expect(MySQLData(.json(ByteBuffer())).sqlValue == .json(ByteBuffer()))
        #expect(MySQLData(type: .json, buffer: nil).sqlValue == .null)
    }

    @Test func uuid() {
        let uuid = UUID()
        // Store as a string in MySQL
        #expect(MySQLData(.uuid(uuid)).sqlValue == .string(uuid.uuidString))
    }
}
