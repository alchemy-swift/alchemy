@testable import Alchemy
import XCTest

final class TrieTests: XCTestCase {
    func testTrie() {
        let trie = Trie<String>()
        
        trie.insert(path: ["one"], value: "foo")
        trie.insert(path: ["one", "two"], value: "bar")
        trie.insert(path: ["one", "two", "three"], value: "baz")
        trie.insert(path: ["one", ":id"], value: "doo")
        trie.insert(path: ["one", ":id", "two"], value: "dar")
        trie.insert(path: [], value: "daz")
        trie.insert(path: [":id0", ":id1", ":id2", ":id3"], value: "hmm")
        
        let result1 = trie.search(path: ["one"])
        let result2 = trie.search(path: ["one", "two"])
        let result3 = trie.search(path: ["one", "two", "three"])
        let result4 = trie.search(path: ["one", "zonk"])
        let result5 = trie.search(path: ["one", "fail", "two"])
        let result6 = trie.search(path: ["one", "aaa", "two"])
        let result7 = trie.search(path: ["one", "bbb", "two"])
        let result8 = trie.search(path: ["1", "2", "3", "4"])
        let result9 = trie.search(path: ["1", "2", "3", "5", "6"])

        XCTAssertEqual(result1?.value, "foo")
        XCTAssertEqual(result1?.parameters, [])
        XCTAssertEqual(result2?.value, "bar")
        XCTAssertEqual(result2?.parameters, [])
        XCTAssertEqual(result3?.value, "baz")
        XCTAssertEqual(result3?.parameters, [])
        XCTAssertEqual(result4?.value, "doo")
        XCTAssertEqual(result4?.parameters, [PathParameter(parameter: "id", stringValue: "zonk")])
        XCTAssertEqual(result5?.value, "dar")
        XCTAssertEqual(result5?.parameters, [PathParameter(parameter: "id", stringValue: "fail")])
        XCTAssertEqual(result6?.value, "dar")
        XCTAssertEqual(result6?.parameters, [PathParameter(parameter: "id", stringValue: "aaa")])
        XCTAssertEqual(result7?.value, "dar")
        XCTAssertEqual(result7?.parameters, [PathParameter(parameter: "id", stringValue: "bbb")])
        XCTAssertEqual(result8?.value, "hmm")
        XCTAssertEqual(result8?.parameters, [
            PathParameter(parameter: "id0", stringValue: "1"),
            PathParameter(parameter: "id1", stringValue: "2"),
            PathParameter(parameter: "id2", stringValue: "3"),
            PathParameter(parameter: "id3", stringValue: "4"),
        ])
        XCTAssertEqual(result9?.0, nil)
        XCTAssertEqual(result9?.1, nil)
    }
}
