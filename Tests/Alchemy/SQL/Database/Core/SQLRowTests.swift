@testable
import Alchemy
import AlchemyTest

final class SQLRowTests: XCTestCase {
    func testDecode() {
        struct Test: Decodable, Equatable {
            let foo: Int
            let bar: String
        }
        
        let row: SQLRow = StubDatabaseRow(data: [
            "foo": 1,
            "bar": "two"
        ])
        XCTAssertEqual(try row.decode(Test.self), Test(foo: 1, bar: "two"))
    }
    
    func testModel() {
        let row: SQLRow = StubDatabaseRow(data: [
            "id": SQLValue.null,
            "bool": false,
            "string": "foo",
            "double": 0.0,
            "float": 0.0,
            "int": 0,
            "int8": 0,
            "int16": 0,
            "int32": 0,
            "int64": 0,
            "uint": 0,
            "uint8": 0,
            "uint16": 0,
            "uint32": 0,
            "uint64": 0,
            "string_enum": "one",
            "nested": SQLValue.json("""
                {"string":"foo"}
                """.data(using: .utf8) ?? Data())
        ])
        XCTAssertEqual(try row.decode(TestModel.self), TestModel())
    }
    
    func testSubscript() {
        let row: SQLRow = StubDatabaseRow(data: ["foo": 1])
        XCTAssertEqual(row["foo"], .int(1))
        XCTAssertEqual(row["bar"], nil)
    }
}

private struct TestModel: Model, Equatable {
    struct Nested: Codable, Equatable { let string: String }
    enum StringEnum: String, ModelEnum { case one }
    
    var id: Int?
    
    // Enum
    var stringEnum: StringEnum = .one
    
    // Keyed
    var bool: Bool = false
    var string: String = "foo"
    var double: Double = 0
    var float: Float = 0
    var int: Int = 0
    var int8: Int8 = 0
    var int16: Int16 = 0
    var int32: Int32 = 0
    var int64: Int64 = 0
    var uint: UInt = 0
    var uint8: UInt8 = 0
    var uint16: UInt16 = 0
    var uint32: UInt32 = 0
    var uint64: UInt64 = 0
    var nested: Nested = Nested(string: "foo")
}
