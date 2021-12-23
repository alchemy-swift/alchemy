@testable
import Alchemy
import AlchemyTest

final class ContentTests: XCTestCase {
    var content: Content2!
    
    override func setUp() {
        super.setUp()
        let data = """
            {
                "string": "string",
                "int": 0,
                "bool": true,
                "double": 1.23,
                "array": [
                    1,
                    2,
                    3
                ],
                "dict": {
                    "one": "one",
                    "two": "two",
                    "three": "three",
                    "four": null
                },
                "jsonArray": [
                    {"foo": "bar"},
                    {"foo": "baz"},
                    {"foo": "tiz"},
                ]
            }
            """.data(using: .utf8)!
        content = try! JSONDecoder().decode(Content2.self, from: data)
    }
    
    func testAccess() throws {
        AssertFalse(content["foo"].exists)
        AssertEqual(try content["string"].string, "string")
        AssertTrue(content.dict.exists)
        AssertEqual(try content["int"].int, 0)
        AssertEqual(try content["bool"].bool, true)
        AssertEqual(try content["double"].double, 1.23)
        XCTAssertThrowsError(try content["array"].string)
        AssertEqual(try content["array"].decode([Int].self).count, 3)
        AssertEqual(try content["array"].array[0].int, 1)
        XCTAssertThrowsError(try content["array"][0].string)
        AssertEqual(try content["array"][0].int, 1)
        AssertEqual(try content["array"][1].int, 2)
        AssertEqual(try content["array"][2].int, 3)
        AssertEqual(try content["dict"]["one"].string, "one")
        AssertEqual(try content["dict"]["two"].string, "two")
        AssertEqual(try content["dict"]["three"].string, "three")
        AssertFalse(try content.dict.three.isNull)
        AssertTrue(content.dict.four.exists)
        AssertTrue(try content.dict.four.isNull)
        AssertTrue(try content["dict"] == [
            "one": "one",
            "two": "two",
            "three": "three",
            "four": nil
        ])
    }
    
    func testFlatten() {
        AssertEqual(content["dict"][*].string.sorted(), ["one", "three", "two", nil])
        AssertEqual(content["jsonArray"][*]["foo"].string, ["bar", "baz", "tiz"])
    }
    
    func testDecode() throws {
        struct DecodableType: Codable, Equatable {
            let one: String
            let two: String
            let three: String
        }
        
        struct ArrayType: Codable, Equatable {
            let foo: String
        }
        
        let expectedStruct = DecodableType(one: "one", two: "two", three: "three")
        AssertEqual(try content["dict"].decode(DecodableType.self), expectedStruct)
        AssertEqual(try content["array"].decode([Int].self), [1, 2, 3])
        AssertEqual(try content["array"].decode([Int8].self), [1, 2, 3])
        let expectedArray = [ArrayType(foo: "bar"), ArrayType(foo: "baz"), ArrayType(foo: "tiz")]
        AssertEqual(try content.jsonArray.decode([ArrayType].self), expectedArray)
    }
}

extension Optional: Comparable where Wrapped == String {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if let lhs = lhs, let rhs = rhs {
            return lhs < rhs
        } else if rhs == nil {
            return true
        } else {
            return false
        }
    }
}
