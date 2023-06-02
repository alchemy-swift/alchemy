@testable
import Alchemy
import AlchemyTest

final class ModelPrimaryKeyTests: XCTestCase {
    func testPrimaryKeyFromSqlValue() {
        let uuid = UUID()
        XCTAssertEqual(try UUID(value: .string(uuid.uuidString)), uuid)
        XCTAssertThrowsError(try UUID(value: .int(1)))
        XCTAssertEqual(try Int(value: .int(1)), 1)
        XCTAssertThrowsError(try Int(value: .string("foo")))
        XCTAssertEqual(try String(value: .string("foo")), "foo")
        XCTAssertThrowsError(try String(value: .bool(false)))
    }
    
    func testPk() {
        XCTAssertEqual(TestModel.pk(123).id, 123)
    }
    
    func testDummyDecoderThrowing() throws {
        let decoder = DummyDecoder()
        XCTAssertThrowsError(try decoder.singleValueContainer())
        XCTAssertThrowsError(try decoder.unkeyedContainer())
        
        let keyed = try decoder.container(keyedBy: DummyKeys.self)
        XCTAssertThrowsError(try keyed.nestedUnkeyedContainer(forKey: .one))
        XCTAssertThrowsError(try keyed.nestedContainer(keyedBy: DummyKeys.self, forKey: .one))
        XCTAssertThrowsError(try keyed.superDecoder())
        XCTAssertThrowsError(try keyed.superDecoder(forKey: .one))
    }
}

private enum DummyKeys: String, CodingKey {
    case one
}

private struct TestModel: Model {
    struct Nested: Codable {
        let string: String
    }
    
    enum Enum: String, ModelEnum {
        case one, two, three
    }
    
    var id: PK<Int> = .new
    
    // Enum
    let `enum`: Enum
    
    // Keyed
    let bool: Bool
    let string: String
    let double: Double
    let float: Float
    let int: Int
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uint: UInt
    let uint8: UInt8
    let uint16: UInt16
    let uint32: UInt32
    let uint64: UInt64
    let nested: Nested
    
    // Arrays
    let boolArray: [Bool]
    let stringArray: [String]
    let doubleArray: [Double]
    let floatArray: [Float]
    let intArray: [Int]
    let int8Array: [Int8]
    let int16Array: [Int16]
    let int32Array: [Int32]
    let int64Array: [Int64]
    let uintArray: [UInt]
    let uint8Array: [UInt8]
    let uint16Array: [UInt16]
    let uint32Array: [UInt32]
    let uint64Array: [UInt64]
    let nestedArray: [Nested]
}
