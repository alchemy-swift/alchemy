@testable import Alchemy
import XCTest

final class TrieTests: XCTestCase {
    func testTrie() {
        let trie = Trie<Int, String>()
        
        trie.insert(path: ["one"], storageKey: 0, value: "foo")
        trie.insert(path: ["one", "two"], storageKey: 1, value: "bar")
        trie.insert(path: ["one", "two", "three"], storageKey: 1, value: "baz")
        trie.insert(path: ["one", ":id"], storageKey: 1, value: "doo")
        trie.insert(path: ["one", ":id", "two"], storageKey: 2, value: "dar")
        trie.insert(path: [], storageKey: 2, value: "daz")
        trie.insert(path: ["one", ":id", "two"], storageKey: 3, value: "zoo")
        trie.insert(path: ["one", ":id", "two"], storageKey: 4, value: "zar")
        trie.insert(path: ["one", ":id", "two"], storageKey: 3, value: "zaz")
        trie.insert(path: [":id0", ":id1", ":id2", ":id3"], storageKey: 0, value: "hmm")
        
        let result1 = trie.search(path: ["one"], storageKey: 0)
        let result2 = trie.search(path: ["one", "two"], storageKey: 1)
        let result3 = trie.search(path: ["one", "two", "three"], storageKey: 1)
        let result4 = trie.search(path: ["one", "zonk"], storageKey: 1)
        let result5 = trie.search(path: ["one", "fail", "two"], storageKey: 2)
        let result6 = trie.search(path: ["one", "aaa", "two"], storageKey: 3)
        let result7 = trie.search(path: ["one", "bbb", "two"], storageKey: 4)
        let result8 = trie.search(path: ["1", "2", "3", "4"], storageKey: 0)
        let result9 = trie.search(path: ["1", "2", "3", "5", "6"], storageKey: 0)

        XCTAssertEqual(result1?.0, "foo")
        XCTAssertEqual(result1?.1, [])
        XCTAssertEqual(result2?.0, "bar")
        XCTAssertEqual(result2?.1, [])
        XCTAssertEqual(result3?.0, "baz")
        XCTAssertEqual(result3?.1, [])
        XCTAssertEqual(result4?.0, "doo")
        XCTAssertEqual(result4?.1, [PathParameter(parameter: "id", stringValue: "zonk")])
        XCTAssertEqual(result5?.0, "dar")
        XCTAssertEqual(result5?.1, [PathParameter(parameter: "id", stringValue: "fail")])
        XCTAssertEqual(result6?.0, "zaz")
        XCTAssertEqual(result6?.1, [PathParameter(parameter: "id", stringValue: "aaa")])
        XCTAssertEqual(result7?.0, "zar")
        XCTAssertEqual(result7?.1, [PathParameter(parameter: "id", stringValue: "bbb")])
        XCTAssertEqual(result8?.0, "hmm")
        XCTAssertEqual(result8?.1, [
            PathParameter(parameter: "id0", stringValue: "1"),
            PathParameter(parameter: "id1", stringValue: "2"),
            PathParameter(parameter: "id2", stringValue: "3"),
            PathParameter(parameter: "id3", stringValue: "4"),
        ])
        XCTAssertEqual(result9?.0, nil)
        XCTAssertEqual(result9?.1, nil)
    }
}
