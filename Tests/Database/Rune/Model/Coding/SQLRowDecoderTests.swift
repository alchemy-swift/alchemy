@testable
import Alchemy
import Foundation
import Testing

struct SQLRowDecoderTests {
    @Test func decodeThrowing() throws {
        let row: SQLRow = [:]
        let decoder = SQLRowDecoder(row: row, keyMapping: .useDefaultKeys, jsonDecoder: JSONDecoder())
        #expect(throws: Error.self) { try decoder.singleValueContainer() }
        #expect(throws: Error.self) { try decoder.unkeyedContainer() }

        let keyed = try decoder.container(keyedBy: DummyKeys.self)
        #expect(throws: Error.self) { try keyed.nestedUnkeyedContainer(forKey: .foo) }
        #expect(throws: Error.self) { try keyed.nestedContainer(keyedBy: DummyKeys.self, forKey: .foo) }
        #expect(throws: Error.self) { try keyed.superDecoder() }
        #expect(throws: Error.self) { try keyed.superDecoder(forKey: .foo) }
    }
}

private enum DummyKeys: String, CodingKey {
    case foo
}
