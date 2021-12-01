@testable
import Alchemy
import AlchemyTest

final class StorageTests: TestCase<TestApp> {
    private var filePath: String = ""
    
    private lazy var allTests = [
        _testCreate,
        _testDelete,
        _testPut,
        _testPathing,
        _testFileStore,
        _testInvalidURL,
    ]
    
    func testConfig() {
        let config = Storage.Config(stores: [.default: .local, 1: .local, 2: .local])
        Storage.configure(using: config)
        XCTAssertNotNil(Storage.resolveOptional(.default))
        XCTAssertNotNil(Storage.resolveOptional(1))
        XCTAssertNotNil(Storage.resolveOptional(2))
    }
    
    func testLocal() async throws {
        let root = NSTemporaryDirectory() + UUID().uuidString
        Storage.register(.local(root: root))
        XCTAssertEqual(root, Store.root)
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
    
    func _testFileStore() async throws {
        try await File(name: filePath, contents: "bar").store()
        AssertTrue(try await Store.exists(filePath))
    }
    
    func _testInvalidURL() async throws {
        do {
            let store: Storage = .local(root: "\\")
            _ = try await store.exists("foo")
            XCTFail("Should throw an error")
        } catch {}
    }
}
