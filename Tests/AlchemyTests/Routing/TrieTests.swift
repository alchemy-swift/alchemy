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
        XCTAssertEqual(result4?.parameters, [Parameter(key: "id", value: "zonk")])
        XCTAssertEqual(result5?.value, "dar")
        XCTAssertEqual(result5?.parameters, [Parameter(key: "id", value: "fail")])
        XCTAssertEqual(result6?.value, "dar")
        XCTAssertEqual(result6?.parameters, [Parameter(key: "id", value: "aaa")])
        XCTAssertEqual(result7?.value, "dar")
        XCTAssertEqual(result7?.parameters, [Parameter(key: "id", value: "bbb")])
        XCTAssertEqual(result8?.value, "hmm")
        XCTAssertEqual(result8?.parameters, [
            Parameter(key: "id0", value: "1"),
            Parameter(key: "id1", value: "2"),
            Parameter(key: "id2", value: "3"),
            Parameter(key: "id3", value: "4"),
        ])
        XCTAssertEqual(result9?.0, nil)
        XCTAssertEqual(result9?.1, nil)
    }
}
