@testable import Alchemy
import AlchemyTest
import XCTest

final class SQLRowEncoderTests: TestCase<TestApp> {
    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake()
    }

    func testEncoding() throws {
        let uuid = UUID()
        let date = Date()
        let json = EverythingModel.Nested(string: "foo", int: 1)
        let model = EverythingModel(
            stringEnum: .one,
            intEnum: .two,
            doubleEnum: .three,
            bool: true,
            string: "foo",
            double: 1.23,
            float: 2.0,
            int: 1,
            int8: 2,
            int16: 3,
            int32: 4,
            int64: 5,
            uint: 6,
            uint8: 7,
            uint16: 8,
            uint32: 9,
            uint64: 10,
            nested: EverythingModel.Nested(string: "foo", int: 1),
            date: date,
            uuid: uuid
        )
        
        let jsonData = try EverythingModel.jsonEncoder.encode(json)
        let expectedFields: [String: SQLConvertible] = [
            "id": 1,
            "string_enum": "one",
            "int_enum": 2,
            "double_enum": 3.0,
            "bool": true,
            "string": "foo",
            "double": 1.23,
            "float": 2.0,
            "int": 1,
            "int8": 2,
            "int16": 3,
            "int32": 4,
            "int64": 5,
            "uint": 6,
            "uint8": 7,
            "uint16": 8,
            "uint32": 9,
            "uint64": 10,
            "string_optional": "bar",
            "nested": SQLValue.json(ByteBuffer(data: jsonData)),
            "date": SQLValue.date(date),
            "uuid": SQLValue.uuid(uuid),
        ]
        
        XCTAssertEqual("everything_models", EverythingModel.table)
        XCTAssertEqual(expectedFields.mapValues(\.sql), try model.fields().mapValues(\.sql))
    }
    
    func testKeyMapping() async throws {
        try await Database.fake(keyMapping: .useDefaultKeys)
        let model = CustomKeyedModel(id: 0)
        let fields = try model.fields()
        XCTAssertEqual("CustomKeyedModels", CustomKeyedModel.table)
        XCTAssertEqual([
            "id",
            "val1",
            "valueTwo",
            "valueThreeInt",
            "snake_case"
        ].sorted(), fields.keys.sorted())
    }
    
    func testCustomJSONEncoder() throws {
        let json = DatabaseJSON(val1: "one", val2: Date())
        let jsonData = try CustomDecoderModel.jsonEncoder.encode(json)
        let model = CustomDecoderModel(json: json)
        
        XCTAssertEqual("custom_decoder_models", CustomDecoderModel.table)
        XCTAssertEqual(try model.fields().mapValues(\.sql), [
            "json": .value(.json(ByteBuffer(data: jsonData)))
        ])
    }
}

private struct DatabaseJSON: Codable {
    var val1: String
    var val2: Date
}

private struct CustomKeyedModel: Model, Codable {
    var id: PK<Int> = .new
    var val1: String = "foo"
    var valueTwo: Int = 0
    var valueThreeInt: Int = 1
    var snake_case: String = "bar"
}

private struct CustomDecoderModel: Model, Codable {
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    
    var id: PK<Int> = .new
    var json: DatabaseJSON
}
