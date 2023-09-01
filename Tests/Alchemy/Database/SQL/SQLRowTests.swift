@testable
import Alchemy
import AlchemyTest

final class SQLRowTests: TestCase<TestApp> {
    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake()
    }

    func testDecode() {
        struct Test: Decodable, Equatable {
            let foo: Int
            let bar: String
        }
        
        let row: SQLRow = [
            "foo": 1,
            "bar": "two"
        ]

        XCTAssertEqual(try row.decode(Test.self), Test(foo: 1, bar: "two"))
    }
    
    func testModel() {
        let date = Date()
        let uuid = UUID()
        let row: SQLRow = [
            "id": 1,
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
            "string_optional": "bar",
            "string_enum": "one",
            "int_enum": 2,
            "double_enum": 3.0,
            "nested": SQLValue.json("""
                {"string":"foo","int":1}
                """),
            "date": SQLValue.date(date),
            "uuid": SQLValue.uuid(uuid),
            "belongs_to_id": 1
        ]

        XCTAssertEqual(try row.decodeModel(EverythingModel.self), EverythingModel(date: date, uuid: uuid))
    }
    
    func testSubscript() {
        let row: SQLRow = ["foo": 1]
        XCTAssertEqual(row["foo"], .int(1))
        XCTAssertEqual(row["bar"], nil)
    }
}

struct EverythingModel: Model, Codable, Equatable {
    struct Nested: Codable, Equatable {
        let string: String
        let int: Int
    }
    enum StringEnum: String, Codable, ModelEnum { case one }
    enum IntEnum: Int, Codable, ModelEnum { case two = 2 }
    enum DoubleEnum: Double, Codable, ModelEnum { case three = 3.0 }

    var id: PK<Int> = .existing(1)

    // Enum
    var stringEnum: StringEnum = .one
    var intEnum: IntEnum = .two
    var doubleEnum: DoubleEnum = .three
    
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
    var intOptional: Int? = nil
    var stringOptional: String? = "bar"
    var nested: Nested = Nested(string: "foo", int: 1)
    var date: Date = Date()
    var uuid: UUID = UUID()
    
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}
