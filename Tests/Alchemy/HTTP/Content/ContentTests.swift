@testable
import Alchemy
import AlchemyTest
import HummingbirdFoundation
import MultipartKit

final class ContentTests: XCTestCase {
    private lazy var allTests = [
        _testAccess,
        _testNestedAccess,
        _testEnumAccess,
        _testFlatten,
        _testDecode,
    ]
    
    func testDict() throws {
        let content = Content(root: .any(Fixtures.dictContent))
        for test in allTests {
            try test(content, true)
        }
        try _testNestedArray(content: content)
        try _testNestedDecode(content: content)
    }
    
    func testMultipart() throws {
        let buffer = ByteBuffer(string: Fixtures.multipartContent)
        let content = FormDataDecoder().content(from: buffer, contentType: .multipart(boundary: Fixtures.multipartBoundary))
        try _testAccess(content: content, allowsNull: false)
        try _testMultipart(content: content)
    }
    
    func testJson() throws {
        let buffer = ByteBuffer(string: Fixtures.jsonContent)
        let content = JSONDecoder().content(from: buffer, contentType: .json)
        for test in allTests {
            try test(content, true)
        }
        try _testNestedArray(content: content)
        try _testNestedDecode(content: content)
    }
    
    func testUrl() throws {
        let buffer = ByteBuffer(string: Fixtures.urlContent)
        let content = URLEncodedFormDecoder().content(from: buffer, contentType: .urlForm)
        for test in allTests {
            try test(content, false)
        }
        try _testNestedDecode(content: content)
    }
    
    func _testAccess(content: Content, allowsNull: Bool) throws {
        AssertTrue(content["foo"] == nil)
        AssertEqual(try content["string"].stringThrowing, "string")
        AssertEqual(try content["string"].decode(String.self), "string")
        AssertEqual(try content["int"].intThrowing, 0)
        AssertEqual(try content["bool"].boolThrowing, true)
        AssertEqual(try content["double"].doubleThrowing, 1.23)
    }
    
    func _testNestedAccess(content: Content, allowsNull: Bool) throws {
        AssertTrue(content.object.four.isNull)
        XCTAssertThrowsError(try content["array"].stringThrowing)
        AssertEqual(try content["array"].arrayThrowing.count, 3)
        XCTAssertThrowsError(try content["array"][0].arrayThrowing)
        AssertEqual(try content["array"][0].intThrowing, 1)
        AssertEqual(try content["array"][1].intThrowing, 2)
        AssertEqual(try content["array"][2].intThrowing, 3)
        AssertEqual(try content["object"]["one"].stringThrowing, "one")
        AssertEqual(try content["object"]["two"].stringThrowing, "two")
        AssertEqual(try content["object"]["three"].stringThrowing, "three")
    }
    
    func _testEnumAccess(content: Content, allowsNull: Bool) throws {
        enum Test: String, Decodable {
            case one, two, three
        }
        
        var expectedDict: [String: Test?] = ["one": .one, "two": .two, "three": .three]
        if allowsNull { expectedDict = ["one": .one, "two": .two, "three": .three, "four": nil] }
        
        AssertEqual(try content.object.one.decode(Test?.self), .one)
        AssertEqual(try content.object.decode([String: Test?].self), expectedDict)
    }
    
    func _testMultipart(content: Content) throws {
        let file = try content["file"].fileThrowing
        AssertEqual(file.name, "a.txt")
        AssertEqual(file.content.buffer.string, "Content of a.txt.\n")
    }
    
    func _testFlatten(content: Content, allowsNull: Bool) throws {
        var expectedArray: [String?] = ["one", "three", "two"]
        if allowsNull { expectedArray.append(nil) }
        AssertEqual(try content["object"][*].decode(Optional<String>.self).sorted(), expectedArray)
    }
    
    func _testDecode(content: Content, allowsNull: Bool) throws {
        struct TopLevelType: Codable, Equatable {
            var string: String = "string"
            var int: Int = 0
            var bool: Bool = true
            var double: Double = 1.23
        }
        
        AssertEqual(try content.decode(TopLevelType.self), TopLevelType())
    }
    
    func _testNestedDecode(content: Content) throws {
        struct NestedType: Codable, Equatable {
            let one: String
            let two: String
            let three: String
        }
        
        let expectedStruct = NestedType(one: "one", two: "two", three: "three")
        AssertEqual(try content["object"].decode(NestedType.self), expectedStruct)
        AssertEqual(try content["array"].decode([Int].self), [1, 2, 3])
        AssertEqual(try content["array"].decode([Int8].self), [1, 2, 3])
    }
    
    func _test(content: Content, allowsNull: Bool) throws {
        struct DecodableType: Codable, Equatable {
            let one: String
            let two: String
            let three: String
        }
        
        struct TopLevelType: Codable, Equatable {
            var string: String = "string"
            var int: Int = 0
            var bool: Bool = false
            var double: Double = 1.23
        }
        
        let expectedStruct = DecodableType(one: "one", two: "two", three: "three")
        AssertEqual(try content.decode(TopLevelType.self), TopLevelType())
        AssertEqual(try content["object"].decode(DecodableType.self), expectedStruct)
        AssertEqual(try content["array"].decode([Int].self), [1, 2, 3])
        AssertEqual(try content["array"].decode([Int8].self), [1, 2, 3])
    }
    
    func _testNestedArray(content: Content) throws {
        struct ArrayType: Codable, Equatable {
            let foo: String
        }
        
        AssertEqual(try content["objectArray"][*]["foo"].stringThrowing, ["bar", "baz", "tiz"])
        let expectedArray = [ArrayType(foo: "bar"), ArrayType(foo: "baz"), ArrayType(foo: "tiz")]
        AssertEqual(try content.objectArray.decode([ArrayType].self), expectedArray)
    }
}

private struct Fixtures {
    static let dictContent: [String: Any] = [
        "string": "string",
        "int": 0,
        "bool": true,
        "double": 1.23,
        "array": [
            1,
            2,
            3
        ],
        "object": [
            "one": "one",
            "two": "two",
            "three": "three",
            "four": nil
        ],
        "objectArray": [
            [
                "foo": "bar"
            ],
            [
                "foo": "baz"
            ],
            [
                "foo": "tiz"
            ]
        ]
    ]
    
    static let multipartBoundary = "---------------------------9051914041544843365972754266"
    static let multipartContent = """
        
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="string"\r
        \r
        string\r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="int"\r
        \r
        0\r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="bool"\r
        \r
        true\r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="double"\r
        \r
        1.23\r
        -----------------------------9051914041544843365972754266\r
        Content-Disposition: form-data; name="file"; filename="a.txt"\r
        Content-Type: text/plain\r
        \r
        Content of a.txt.
        \r
        -----------------------------9051914041544843365972754266--\r
        
        """
    
    static let jsonContent = """
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
        "object": {
            "one": "one",
            "two": "two",
            "three": "three",
            "four": null
        },
        "objectArray": [
            {
                "foo": "bar"
            },
            {
                "foo": "baz"
            },
            {
                "foo": "tiz"
            }
        ]
    }
    """
    
    static let urlContent = """
    string=string&int=0&bool=true&double=1.23&array[]=1&array[]=2&array[]=3&object[one]=one&object[two]=two&object[three]=three
    """
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
