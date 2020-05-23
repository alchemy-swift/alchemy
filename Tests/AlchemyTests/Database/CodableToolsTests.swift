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

extension DatabaseValue: Equatable {
    public static func == (lhs: DatabaseValue, rhs: DatabaseValue) -> Bool {
        if case .int = lhs, case .int = rhs {
            return true
        } else if case .double = lhs, case .double = rhs {
            return true
        } else if case .bool = lhs, case .bool = rhs {
            return true
        } else if case .string = lhs, case .string = rhs {
            return true
        } else if case .date = lhs, case .date = rhs {
            return true
        } else if case .json = lhs, case .json = rhs {
            return true
        } else if case .uuid = lhs, case .uuid = rhs {
            return true
        } else if case .arrayInt = lhs, case .arrayInt = rhs {
            return true
        } else if case .arrayDouble = lhs, case .arrayDouble = rhs {
            return true
        } else if case .arrayBool = lhs, case .arrayBool = rhs {
            return true
        } else if case .arrayString = lhs, case .arrayString = rhs {
            return true
        } else if case .arrayDate = lhs, case .arrayDate = rhs {
            return true
        } else if case .arrayJSON = lhs, case .arrayJSON = rhs {
            return true
        } else if case .arrayUUID = lhs, case .arrayUUID = rhs {
            return true
        } else {
            return false
        }
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

private struct StoredPropertyStruct: DatabaseCodable {
    static var tableName = "stored_property"
    
    struct SomeJSON: DatabaseJSON {
        let string = "text"
    }
    
    let id = UUID()
    let string = "value"
    let int = 1
    let double = 1.0
    let bool = false
    let date = Date()
    let json = SomeJSON()
}

private struct InvalidPropertyStruct: DatabaseCodable {
    static var tableName = "invalid_property"
    
    let id = UUID()
    let data = Data()
}

private enum CodingKeys: String, CodingKey {
    case usa = "united_states_of_america"
    case ca = "canada"
    case aus = "australia"
    case mexico
}
