@testable import Alchemy
import AlchemyTesting
import Foundation

struct SQLRowEncoderTests {
    @Test func encoding() throws {
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
        let expectedFields: SQLFields = [
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
        
        #expect("everything_models" == EverythingModel.table)
        #expect(try expectedFields.mapValues(\.sql) == model.fields().mapValues(\.sql))
    }
    
    @Test func customJSONEncoder() throws {
        let json = DatabaseJSON(val1: "one", val2: Date())
        let jsonData = try CustomDecoderModel.jsonEncoder.encode(json)
        let model = CustomDecoderModel(json: json)
        
        #expect("custom_decoder_models" == CustomDecoderModel.table)
        #expect(try model.fields().mapValues(\.sql) == [
            "json": .value(.json(ByteBuffer(data: jsonData)))
        ])
    }
}

private struct DatabaseJSON: Codable {
    var val1: String
    var val2: Date
}

@Model
private struct CustomKeyedModel {
    var id: Int
    var val1: String = "foo"
    var valueTwo: Int = 0
    var valueThreeInt: Int = 1
    var snake_case: String = "bar"
}

@Model
private struct CustomDecoderModel {
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    
    var id: Int
    var json: DatabaseJSON
}
