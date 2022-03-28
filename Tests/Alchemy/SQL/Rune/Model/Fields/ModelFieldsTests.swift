@testable import Alchemy
import XCTest

final class ModelFieldsTests: XCTestCase {
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
            uuid: uuid,
            belongsTo: .pk(1)
        )
        
        let jsonData = try EverythingModel.jsonEncoder.encode(json)
        let expectedFields: [SQLField] = [
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
            "nested": SQLValue.json(jsonData),
            "date": SQLValue.date(date),
            "uuid": SQLValue.uuid(uuid),
            "belongs_to_id": 1,
            "belongs_to_optional_id": SQLValue.null,
        ]
        
        XCTAssertEqual("everything_models", EverythingModel.tableName)
        XCTAssertEqual(expectedFields, try model.fields())
    }
    
    func testKeyMapping() throws {
        let model = CustomKeyedModel.pk(0)
        let fields = try model.fields()
        XCTAssertEqual("CustomKeyedModels", CustomKeyedModel.tableName)
        XCTAssertEqual([
            "id",
            "val1",
            "valueTwo",
            "valueThreeInt",
            "snake_case"
        ].sorted(), fields.map { $0.column }.sorted())
    }
    
    func testCustomJSONEncoder() throws {
        let json = DatabaseJSON(val1: "one", val2: Date())
        let jsonData = try CustomDecoderModel.jsonEncoder.encode(json)
        let model = CustomDecoderModel(json: json)
        
        XCTAssertEqual("custom_decoder_models", CustomDecoderModel.tableName)
        XCTAssertEqual(try model.fields(), [
            "json": SQLValue.json(jsonData)
        ])
    }
}

private struct DatabaseJSON: Codable {
    var val1: String
    var val2: Date
}

private struct CustomKeyedModel: Model {
    static var keyMapping: DatabaseKeyMapping = .useDefaultKeys
    
    var id: Int?
    var val1: String = "foo"
    var valueTwo: Int = 0
    var valueThreeInt: Int = 1
    var snake_case: String = "bar"
}

private struct CustomDecoderModel: Model {
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    
    var id: Int?
    var json: DatabaseJSON
}

extension Array: ExpressibleByDictionaryLiteral where Element == SQLField {
    public init(dictionaryLiteral elements: (String, SQLValueConvertible)...) {
        self = elements.map { SQLField(column: $0, value: $1.sqlValue) }
    }
}
