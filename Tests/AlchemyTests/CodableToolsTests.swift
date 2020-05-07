@testable import Alchemy
import XCTest

private struct SomeStruct: Codable {
    let immutableString: String = "Josh"
    var data: Data = Data()
    var string: String = "Sir"
    var uuid: UUID = UUID()
    var url: URL = URL(string: "https://www.postgresql.org/docs/9.5/datatype.html")!
    var int: Int = 26
    var int8: Int8 = 2
    var int32: Int32 = 4
    var int64: Int64 = 8
    var double: Double = 26.0
    var date: Date = Date()
    var date2: Date = Date()
    var bool: Bool = false
    var optional: String? = nil
    var json: OtherStruct = OtherStruct(value: "someValue", other: 5)
    var array: [String] = ["first", "second", "third"]
}

/// Example of an type conforming to `KeyPathCodable`.
private struct OtherStruct: Codable {
    let value: String
    let other: Int
}

private enum CodingKeys: String, CodingKey {
    case usa = "united_states_of_america"
    case ca = "canada"
    case aus = "australia"
    case mexico
}

final class CodableToolsTests: XCTestCase {
    func testFetchKeyPathName() {
        XCTAssertEqual((\SomeStruct.immutableString).storedName(), "immutableString")
        XCTAssertEqual((\SomeStruct.data).storedName(), "data")
        XCTAssertEqual((\SomeStruct.string).storedName(), "string")
        XCTAssertEqual((\SomeStruct.uuid).storedName(), "uuid")
        XCTAssertEqual((\SomeStruct.url).storedName(), "url")
        XCTAssertEqual((\SomeStruct.int).storedName(), "int")
        XCTAssertEqual((\SomeStruct.int8).storedName(), "int8")
        XCTAssertEqual((\SomeStruct.int32).storedName(), "int32")
        XCTAssertEqual((\SomeStruct.int64).storedName(), "int64")
        XCTAssertEqual((\SomeStruct.double).storedName(), "double")
        XCTAssertEqual((\SomeStruct.date).storedName(), "date")
        XCTAssertEqual((\SomeStruct.date2).storedName(), "date2")
        XCTAssertEqual((\SomeStruct.bool).storedName(), "bool")
        XCTAssertEqual((\SomeStruct.optional).storedName(), "optional")
        XCTAssertEqual((\SomeStruct.json).storedName(), "json")
        XCTAssertEqual((\SomeStruct.array).storedName(), "array")
    }
    
    func testCodingKey() {
        XCTAssertEqual(CodingKeys.usa.caseName(), "usa")
        XCTAssertEqual(CodingKeys.ca.caseName(), "ca")
        XCTAssertEqual(CodingKeys.aus.caseName(), "aus")
        XCTAssertEqual(CodingKeys.mexico.caseName(), "mexico")
    }
    
    func testEncodableProperty() {
        
    }
}
