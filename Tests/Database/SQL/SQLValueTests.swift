@testable
import Alchemy
import Foundation
import Testing

struct SQLValueTests {
    @Test func null() {
        #expect(throws: Error.self) { try SQLValue.null.int() }
        #expect(throws: Error.self) { try SQLValue.null.double() }
        #expect(throws: Error.self) { try SQLValue.null.bool() }
        #expect(throws: Error.self) { try SQLValue.null.string() }
        #expect(throws: Error.self) { try SQLValue.null.json() }
        #expect(throws: Error.self) { try SQLValue.null.date() }
        #expect(throws: Error.self) { try SQLValue.null.uuid("foo") }
    }

    @Test func int() throws {
        #expect(try SQLValue.int(1).int() == 1)
        #expect(throws: Error.self) { try SQLValue.string("foo").int() }
    }

    @Test func double() throws {
        #expect(try SQLValue.double(1.0).double() == 1.0)
        #expect(throws: Error.self) { try SQLValue.string("foo").double() }
    }

    @Test func bool() throws {
        #expect(try SQLValue.bool(false).bool() == false)
        #expect(try SQLValue.int(1).bool() == true)
        #expect(throws: Error.self) { try SQLValue.string("foo").bool() }
    }

    @Test func string() throws {
        #expect(try SQLValue.string("foo").string() == "foo")
        #expect(try SQLValue.int(1).string() == "1")
    }

    @Test func date() throws {
        let date = Date()
        #expect(try SQLValue.date(date).date() == date)
        #expect(try SQLValue.int(1).date() == Date(timeIntervalSince1970: 1))
    }

    @Test func dateIso8601() throws {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        let roundedDate = formatter.date(from: dateString) ?? Date()
        #expect(try SQLValue.string(formatter.string(from: date)).date() == roundedDate)
        #expect(throws: Error.self) { try SQLValue.string("").date() }
    }

    @Test func json() throws {
        let jsonString = """
        {"foo":1}
        """
        #expect(try SQLValue.json(ByteBuffer()).json() == ByteBuffer())
        #expect(try SQLValue.string(jsonString).json().data == jsonString.data(using: .utf8))
        #expect(throws: Error.self) { try SQLValue.int(1).json() }
    }

    @Test func uuid() throws {
        let uuid = UUID()
        #expect(try SQLValue.uuid(uuid).uuid() == uuid)
        #expect(try SQLValue.string(uuid.uuidString).uuid() == uuid)
        #expect(throws: Error.self) { try SQLValue.string("").uuid() }
        #expect(throws: Error.self) { try SQLValue.int(1).uuid("foo") }
    }

    @Test func description() {
        #expect(SQLValue.int(0).description == "0")
        #expect(SQLValue.double(1.23).description == "1.23")
        #expect(SQLValue.bool(true).description == "true")
        #expect(SQLValue.string("foo").description == "'foo'")
        let date = Date()
        #expect(SQLValue.date(date).description == "\(date)")
        let jsonString = """
        {"foo":"bar"}
        """
        let bytes = ByteBuffer(data: jsonString.data(using: .utf8) ?? Data())
        #expect(SQLValue.json(bytes).description == "\(jsonString)")
        let uuid = UUID()
        #expect(SQLValue.uuid(uuid).description == "\(uuid.uuidString)")
        #expect(SQLValue.null.description == "NULL")
    }

    @Test func rawSQLString() {
        let jsonString = """
        {"foo":"bar"}
        """
        let bytes = ByteBuffer(data: jsonString.data(using: .utf8) ?? Data())
        #expect(SQLValue.json(bytes).rawSQLString == "\(jsonString)")
        #expect(SQLValue.null.rawSQLString == "NULL")
        #expect(SQLValue.string("foo").rawSQLString == "'foo'")
    }
}
