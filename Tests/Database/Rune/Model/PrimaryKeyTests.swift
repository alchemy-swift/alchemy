@testable
import Alchemy
import Foundation
import Testing

struct PrimaryKeyTests {
    @Test func primaryKeyFromSqlValue() throws {
        let uuid = UUID()
        #expect(try UUID(value: .string(uuid.uuidString)) == uuid)
        #expect(throws: Error.self) { try UUID(value: .int(1)) }
        #expect(try Int(value: .int(1)) == 1)
        #expect(throws: Error.self) { try Int(value: .string("foo")) }
        #expect(try String(value: .string("foo")) == "foo")
        #expect(throws: Error.self) { try String(value: .null) }
    }
}
