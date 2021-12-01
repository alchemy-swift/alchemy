@testable
import Alchemy
import AlchemyTest

final class StorageTests: TestCase<TestApp> {
    private var filePath: String = ""
    
    private lazy var allTests = [
        _testCreate,
        _testDelete,
        _testPut,
        _testPathing
    ]
    
    func testLocal() async throws {
        Storage.register(.local(root: NSTemporaryDirectory() + UUID().uuidString))
        for test in allTests {
            filePath = UUID().uuidString + ".txt"
            try await test()
        }
    }
    
    func _testCreate() async throws {
        AssertFalse(try await Store.exists(filePath))
        do {
            _ = try await Store.get(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Store.create(filePath, contents: "1;2;3")
        AssertTrue(try await Store.exists(filePath))
        let file = try await Store.get(filePath)
        AssertEqual(file.name, filePath)
        AssertEqual(file.contents, "1;2;3")
    }
    
    func _testDelete() async throws {
        do {
            try await Store.delete(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Store.create(filePath, contents: "123")
        try await Store.delete(filePath)
        AssertFalse(try await Store.exists(filePath))
    }
    
    func _testPut() async throws {
        let file = File(name: filePath, contents: "foo")
        try await Store.put(file)
        AssertTrue(try await Store.exists(filePath))
        try await Store.put(file, in: "foo/bar")
        AssertTrue(try await Store.exists("foo/bar/\(filePath)"))
    }
    
    func _testPathing() async throws {
        try await Store.create("foo/bar/baz/\(filePath)", contents: "foo")
        AssertFalse(try await Store.exists(filePath))
        AssertTrue(try await Store.exists("foo/bar/baz/\(filePath)"))
        let file = try await Store.get("foo/bar/baz/\(filePath)")
        AssertEqual(file.name, filePath)
        AssertEqual(file.contents, "foo")
        try await Store.delete("foo/bar/baz/\(filePath)")
        AssertFalse(try await Store.exists("foo/bar/baz/\(filePath)"))
    }
}

extension ByteBuffer: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
}
