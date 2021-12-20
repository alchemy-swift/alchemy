@testable
import Alchemy
import AlchemyTest

final class ContentTests: XCTestCase {
    var content: Content = Content(value: "foo")
    
    override func setUp() {
        super.setUp()
        content = Content(dict: [
            "string": "string",
            "int": 0,
            "bool": true,
            "double": 1.23,
            "array": [
                1,
                2,
                3
            ],
            "dict": [
                "one": "one",
                "two": "two",
                "three": "three",
                "four": nil
            ],
            "jsonArray": [
                ["foo": "bar"],
                ["foo": "baz"],
                ["foo": "tiz"],
            ]
        ])
    }
    
    func testAccess() {
        AssertTrue(content["foo"] == nil)
        AssertEqual(content["string"].string, "string")
        AssertTrue(content.dict.four == nil)
        AssertEqual(content["int"].int, 0)
        AssertEqual(content["bool"].bool, true)
        AssertEqual(content["double"].double, 1.23)
        AssertEqual(content["array"].string, nil)
        AssertEqual(content["array"].array?.count, 3)
        AssertEqual(content["array"][0].string, nil)
        AssertEqual(content["array"][0].int, 1)
        AssertEqual(content["array"][1].int, 2)
        AssertEqual(content["array"][2].int, 3)
        AssertEqual(content["dict"]["one"].string, "one")
        AssertEqual(content["dict"]["two"].string, "two")
        AssertEqual(content["dict"]["three"].string, "three")
        AssertEqual(content["dict"].dictionary?.string, [
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
