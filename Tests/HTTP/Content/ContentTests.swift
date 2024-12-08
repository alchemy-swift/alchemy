import Alchemy
import Foundation
import MultipartKit
import Testing

final class ContentTests {
    @Test(arguments: [Content.dict, .json, .url, .multipart])
    func access(content: Content) throws {
        #expect(content["foo"] == nil)
        #expect(try content["string"].stringThrowing == "string")
        #expect(try content["string"].decode(String.self) == "string")
        #expect(try content["int"].intThrowing == 0)
        #expect(try content["bool"].boolThrowing == true)
        #expect(try content["double"].doubleThrowing == 1.23)
    }

    @Test(arguments: [Content.dict, .json, .url])
    func nestedAccess(content: Content) throws {
        #expect(content.object.four.isNull)
        #expect(throws: Error.self) { try content["array"].stringThrowing }
        #expect(try content["array"].arrayThrowing.count == 3)
        #expect(throws: Error.self) { try content["array"][0].arrayThrowing }
        #expect(try content["array"][0].intThrowing == 1)
        #expect(try content["array"][1].intThrowing == 2)
        #expect(try content["array"][2].intThrowing == 3)
        #expect(try content["object"]["one"].stringThrowing == "one")
        #expect(try content["object"]["two"].stringThrowing == "two")
        #expect(try content["object"]["three"].stringThrowing == "three")
    }

    @Test(arguments: [Content.dict, .json])
    func enumAccess(content: Content) throws {
        let expected: [String: TestEnum?] = ["one": .one, "two": .two, "three": .three, "four": nil]
        #expect(try content.object.one.decode(TestEnum?.self) == .one)
        #expect(try content.object.decode([String: TestEnum?].self) == expected)
    }

    @Test func urlEnumAccess() throws {
        let content = Content.url
        let expected: [String: TestEnum?] = ["one": .one, "two": .two, "three": .three]
        #expect(try content.object.one.decode(TestEnum?.self) == .one)
        #expect(try content.object.decode([String: TestEnum?].self) == expected)
    }

    @Test func multipart() throws {
        let file = try Content.multipart["file"].fileThrowing
        #expect(file.name == "a.txt")
        #expect(file.content?.string == "Content of a.txt.\n")
    }


    @Test(arguments: [Content.dict, .json])
    func flatten(content: Content) throws {
        let expectedArray = ["one", "three", "two", nil]
        #expect(try content["object"][*].decodeEach(String?.self).sorted() == expectedArray)
    }

    @Test func urlFlatten() throws {
        let expectedArray = ["one", "three", "two"]
        #expect(try Content.url["object"][*].decodeEach(String?.self).sorted() == expectedArray)
    }

    @Test(arguments: [Content.dict, .json, .url])
    func decode(content: Content) throws {
        struct TopLevelType: Codable, Equatable {
            var string: String = "string"
            var int: Int = 0
            var bool: Bool = true
            var double: Double = 1.23
        }

        #expect(try content.decode(TopLevelType.self) == TopLevelType())
    }

    @Test(arguments: [Content.dict, .json, .url])
    func nestedDecode(content: Content) throws {
        struct NestedType: Codable, Equatable {
            let one: String
            let two: String
            let three: String
        }

        let expectedStruct = NestedType(one: "one", two: "two", three: "three")
        #expect(try content["object"].decode(NestedType.self) == expectedStruct)
        #expect(try content["array"].decode([Int].self) == [1, 2, 3])
        #expect(try content["array"].decode([Int8].self) == [1, 2, 3])
    }

    @Test(arguments: [Content.dict, .json])
    func nestedArray(content: Content) throws {
        struct ArrayType: Codable, Equatable {
            let foo: String
        }

        #expect(try content["objectArray"][*]["foo"].stringThrowing == ["bar", "baz", "tiz"])
        let expectedArray = [ArrayType(foo: "bar"), ArrayType(foo: "baz"), ArrayType(foo: "tiz")]
        #expect(try content.objectArray.decode([ArrayType].self) == expectedArray)
    }
}

private enum TestEnum: String, Decodable {
    case one, two, three
}

private extension Content {
    static var json: Content {
        let buffer = ByteBuffer(string: Fixtures.jsonContent)
        return JSONDecoder().content(from: buffer, contentType: .json)
    }

    static var dict: Content {
        Content(value: .dictionary(Fixtures.dictContent))
    }

    static var url: Content {
        let buffer = ByteBuffer(string: Fixtures.urlContent)
        return URLEncodedFormDecoder().content(from: buffer, contentType: .urlForm)
    }

    static var multipart: Content {
        let buffer = ByteBuffer(string: Fixtures.multipartContent)
        return FormDataDecoder().content(from: buffer, contentType: .multipart(boundary: Fixtures.multipartBoundary))
    }
}

private struct Fixtures {
    static let dictContent: [String: Content.Value] = [
        "string": "string",
        "int": 0,
        "bool": true,
        "double": 1.23,
        "array": [
            1,
            2,
            3,
        ],
        "object": [
            "one": "one",
            "two": "two",
            "three": "three",
            "four": nil,
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
            ],
        ],
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

private extension [String?] {
    func sorted() -> [String?] {
        sorted { lhs, rhs in
            if let lhs = lhs, let rhs = rhs {
                return lhs < rhs
            } else if rhs == nil {
                return true
            } else {
                return false
            }
        }
    }
}
