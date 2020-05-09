@testable import Alchemy
import XCTest

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
        XCTAssertEqual((\SomeStruct.optionalNil).storedName(), "optionalNil")
        XCTAssertEqual((\SomeStruct.optionalValue).storedName(), "optionalValue")
        XCTAssertEqual((\SomeStruct.json).storedName(), "json")
        XCTAssertEqual((\SomeStruct.array).storedName(), "array")
    }
    
    func testCodingKey() {
        XCTAssertEqual(CodingKeys.usa.caseName(), "usa")
        XCTAssertEqual(CodingKeys.ca.caseName(), "ca")
        XCTAssertEqual(CodingKeys.aus.caseName(), "aus")
        XCTAssertEqual(CodingKeys.mexico.caseName(), "mexico")
    }
    
    func testEncodableProperty() throws {
        let properties = try StoredPropertyStruct()
            .storedProperties()
        
        guard properties.count == 7 else {
            return XCTFail("The property count should be 7.")
        }
        
        XCTAssertEqual(properties[0], StoredProperty(key: "uuid", type: .uuid(UUID())))
        XCTAssertEqual(properties[1], StoredProperty(key: "string", type: .string("")))
        XCTAssertEqual(properties[2], StoredProperty(key: "int", type: .int(1)))
        XCTAssertEqual(properties[3], StoredProperty(key: "double", type: .double(1.0)))
        XCTAssertEqual(properties[4], StoredProperty(key: "bool", type: .bool(false)))
        XCTAssertEqual(properties[5], StoredProperty(key: "date", type: .date(Date())))
        XCTAssertEqual(properties[6], StoredProperty(key: "json", type: .json(Data())))
    }
    
    func testInvalidPropertyTypeThrows() {
        XCTAssertThrowsError(try InvalidPropertyStruct().storedProperties())
    }
}

private struct SomeStruct: Codable {
    let immutableString: String = "Josh"
    var data: Data = Data()
    var string: String = "Sir"
    var uuid: UUID = UUID()
    var url: URL = URL(string: "https://www.postgresql.org/docs/9.5/datatype.html")!
    var int: Int = 26
    var int8: Int8 = 2
    var int16: Int16 = 4
    var int32: Int32 = 8
    var int64: Int64 = 16
    var float: Float = 1.0
    var double: Double = 26.0
    var date: Date = Date()
    var date2: Date = Date()
    var bool: Bool = false
    var optionalNil: String? = nil
    var optionalValue: String? = ""
    var json: OtherStruct = OtherStruct(value: "someValue", other: 5)
    var array: [String] = ["first", "second", "third"]
}

private struct OtherStruct: Codable {
    let value: String
    let other: Int
}

private struct StoredPropertyStruct: Codable {
    struct SomeJSON: JSON {
        let string = "text"
    }
    
    let uuid = UUID()
    let string = "value"
    let int = 1
    let double = 1.0
    let bool = false
    let date = Date()
    let json = SomeJSON()
}

private struct InvalidPropertyStruct: Codable {
    let data = Data()
}

private enum CodingKeys: String, CodingKey {
    case usa = "united_states_of_america"
    case ca = "canada"
    case aus = "australia"
    case mexico
}
