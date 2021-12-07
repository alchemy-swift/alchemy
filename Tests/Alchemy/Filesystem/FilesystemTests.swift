@testable
import Alchemy
import AlchemyTest

final class FilesystemTests: TestCase<TestApp> {
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
        let config = Filesystem.Config(disks: [.default: .local, 1: .local, 2: .local])
        Filesystem.configure(using: config)
        XCTAssertNotNil(Filesystem.resolveOptional(.default))
        XCTAssertNotNil(Filesystem.resolveOptional(1))
        XCTAssertNotNil(Filesystem.resolveOptional(2))
    }
    
    func testLocal() async throws {
        let root = NSTemporaryDirectory() + UUID().uuidString
        Filesystem.register(.local(root: root))
        XCTAssertEqual(root, Storage.root)
        for test in allTests {
            filePath = UUID().uuidString + ".txt"
            try await test()
        }
    }
    
    func _testCreate() async throws {
        AssertFalse(try await Storage.exists(filePath))
        do {
            _ = try await Storage.get(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Storage.create(filePath, content: "1;2;3")
        AssertTrue(try await Storage.exists(filePath))
        let file = try await Storage.get(filePath)
        AssertEqual(file.name, filePath)
        AssertEqual(try await file.content.collect(), "1;2;3")
    }
    
    func _testDelete() async throws {
        do {
            try await Storage.delete(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Storage.create(filePath, content: "123")
        try await Storage.delete(filePath)
        AssertFalse(try await Storage.exists(filePath))
    }
    
    func _testPut() async throws {
        let file = File(name: filePath, size: 3, content: "foo")
        try await Storage.put(file)
        AssertTrue(try await Storage.exists(filePath))
        try await Storage.put(file, in: "foo/bar")
        AssertTrue(try await Storage.exists("foo/bar/\(filePath)"))
    }
    
    func _testPathing() async throws {
        try await Storage.create("foo/bar/baz/\(filePath)", content: "foo")
        AssertFalse(try await Storage.exists(filePath))
        AssertTrue(try await Storage.exists("foo/bar/baz/\(filePath)"))
        let file = try await Storage.get("foo/bar/baz/\(filePath)")
        AssertEqual(file.name, filePath)
        AssertEqual(try await file.content.collect(), "foo")
        try await Storage.delete("foo/bar/baz/\(filePath)")
        AssertFalse(try await Storage.exists("foo/bar/baz/\(filePath)"))
    }
    
    func _testFileStore() async throws {
        try await File(name: filePath, size: 3, content: "bar").store()
        AssertTrue(try await Storage.exists(filePath))
    }
    
    func _testInvalidURL() async throws {
        do {
            let store: Filesystem = .local(root: "\\")
            _ = try await store.exists("foo")
            XCTFail("Should throw an error")
        } catch {}
    }
}