@testable import Alchemy
import XCTest

final class DatabaseEncodingTests: XCTestCase {
    func testEncoding() throws {
        let uuid = UUID()
        let date = Date()
        let json = DatabaseJSON(val1: "sample", val2: Date())
        let model = TestModel(
            string: "one",
            int: 2,
            uuid: uuid,
            date: date,
            bool: true,
            double: 3.14159,
            json: json,
            stringEnum: .third,
            intEnum: .two,
            belongsTo: .init(5)
        )
        
        let jsonData = try TestModel.jsonEncoder.encode(json)
        let expectedFields: [DatabaseField] = [
            DatabaseField(column: "string", value: .string("one")),
            DatabaseField(column: "int", value: .int(2)),
            DatabaseField(column: "uuid", value: .uuid(uuid)),
            DatabaseField(column: "date", value: .date(date)),
            DatabaseField(column: "bool", value: .bool(true)),
            DatabaseField(column: "double", value: .double(3.14159)),
            DatabaseField(column: "json", value: .json(jsonData)),
            DatabaseField(column: "string_enum", value: .string("third")),
            DatabaseField(column: "int_enum", value: .int(1)),
            DatabaseField(column: "test_conversion_caps_test", value: .string("")),
            DatabaseField(column: "test_conversion123", value: .string("")),
            DatabaseField(column: "belongs_to_id", value: .int(5)),
        ]
        
        XCTAssertEqual("test_models", TestModel.tableName)
        XCTAssertEqual(expectedFields, try model.fields())
    }
    
    func testKeyMapping() throws {
        let model = CustomKeyedModel(belongsTo: .init(9))
        let fields = try model.fields()
        XCTAssertEqual("CustomKeyedModels", CustomKeyedModel.tableName)
        XCTAssertEqual([
            "val1",
            "valueTwo",
            "valueThreeInt",
            "snake_case",
            "belongsToId"
        ], fields.map(\.column))
    }
    
    func testCustomJSONEncoder() throws {
        let json = DatabaseJSON(val1: "one", val2: Date())
        let jsonData = try CustomDecoderModel.jsonEncoder.encode(json)
        let model = CustomDecoderModel(json: json)
        let expectedFields: [DatabaseField] = [
            DatabaseField(column: "json", value: .json(jsonData))
        ]
        
        XCTAssertEqual("custom_decoder_models", CustomDecoderModel.tableName)
        XCTAssertEqual(expectedFields, try model.fields())
    }
}

private struct DatabaseJSON: Codable {
    var val1: String
    var val2: Date
}

private enum IntEnum: Int, ModelEnum {
    case one, two, three
}

private enum StringEnum: String, ModelEnum {
    case first, second, third
}

private struct TestModel: Model {
    var id: Int?
    var string: String
    var int: Int
    var uuid: UUID
    var date: Date
    var bool: Bool
    var double: Double
    var json: DatabaseJSON
    var stringEnum: StringEnum
    var intEnum: IntEnum
    var testConversionCAPSTest: String = ""
    var testConversion123: String = ""
    
    @BelongsTo
    var belongsTo: TestModel
    
    @HasOne(to: \.$belongsTo)
    var hasOne: TestModel
    
    @HasMany(to: \.$belongsTo)
    var hasMany: [TestModel]
    
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

private struct CustomKeyedModel: Model {
    var id: Int?
    var val1: String = "foo"
    var valueTwo: Int = 0
    var valueThreeInt: Int = 1
    var snake_case: String = "bar"
    
    @BelongsTo
    var belongsTo: CustomKeyedModel
    static var keyMapping: DatabaseKeyMapping = .useDefaultKeys
}

private struct CustomDecoderModel: Model {
    var id: Int?
    var json: DatabaseJSON
    
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
