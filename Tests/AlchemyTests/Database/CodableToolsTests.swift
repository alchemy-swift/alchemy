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
        let properties = try StoredPropertyStruct().fields()
        
        guard properties.count == 7 else {
            return XCTFail("The property count should be 7.")
        }
        
        XCTAssertEqual(properties[0], DatabaseField(column: "id", value: .uuid(UUID())))
        XCTAssertEqual(properties[1], DatabaseField(column: "string", value: .string("")))
        XCTAssertEqual(properties[2], DatabaseField(column: "int", value: .int(1)))
        XCTAssertEqual(properties[3], DatabaseField(column: "double", value: .double(1.0)))
        XCTAssertEqual(properties[4], DatabaseField(column: "bool", value: .bool(false)))
        XCTAssertEqual(properties[5], DatabaseField(column: "date", value: .date(Date())))
        XCTAssertEqual(properties[6], DatabaseField(column: "json", value: .json(Data())))
    }
    
    func testInvalidPropertyTypeThrows() {
        XCTAssertThrowsError(try InvalidPropertyStruct().fields())
    }
}

extension DatabaseField: Equatable {
    public static func == (lhs: DatabaseField, rhs: DatabaseField) -> Bool {
        lhs.column == rhs.column && lhs.value == rhs.value
    }
}

private struct SomeStruct: Codable {
    var immutableString: String = "Josh"
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

private struct StoredPropertyStruct: DatabaseCodable {
    static var tableName = "stored_property"
    
    struct SomeJSON: DatabaseJSON {
        var string = "text"
    }
    
    var id: UUID? = UUID()
    var string = "value"
    var int = 1
    var double = 1.0
    var bool = false
    var date = Date()
    var json = SomeJSON()
}

private struct InvalidPropertyStruct: DatabaseCodable {
    static var tableName = "invalid_property"
    
    var id: UUID? = UUID()
    var data = Data()
}

private enum CodingKeys: String, CodingKey {
    case usa = "united_states_of_america"
    case ca = "canada"
    case aus = "australia"
    case mexico
}
