@testable
import Alchemy
import AlchemyTest

final class FilesystemTests: TestCase<TestApp> {
    private var filePath: String = ""
    private var root: String = ""

    override func setUp() async throws {
        try await super.setUp()
        let root = NSTemporaryDirectory() + UUID().uuidString
        Container.register(Filesystem.local(root: root)).singleton()
        self.root = root
        self.filePath = UUID().uuidString + ".txt"
    }

    func testPlugin() async throws {
        let plugin = Filesystems(default: 1, disks: [1: .local, 2: .local])
        plugin.boot(app: app)
        XCTAssertNotNil(Container.resolve(Filesystem.self))
        XCTAssertNotNil(Container.resolve(Filesystem.self, id: 1))
        XCTAssertNotNil(Container.resolve(Filesystem.self, id: 2))
    }

    func testLocalRoot() {
        XCTAssertEqual(root, Storage.root)
    }

    func testLocalCreate() async throws {
        AssertFalse(try await Storage.exists(filePath))
        do {
            _ = try await Storage.get(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Storage.create(filePath, content: "1;2;3")
        AssertTrue(try await Storage.exists(filePath))
        let file = try await Storage.get(filePath)
        AssertEqual(file.name, filePath)
        AssertEqual(try await file.getContent().collect(), ByteBuffer(string: "1;2;3"))
    }

    
    func testLocalDelete() async throws {
        do {
            try await Storage.delete(filePath)
            XCTFail("Should throw an error")
        } catch {}
        try await Storage.create(filePath, content: "123")
        try await Storage.delete(filePath)
        AssertFalse(try await Storage.exists(filePath))
    }
    
    func testLocalPut() async throws {
        let file = File(name: filePath, source: .raw, content: "foo", size: 3)
        try await Storage.put(file, as: filePath)
        AssertTrue(try await Storage.exists(filePath))
        try await Storage.put(file, in: "foo/bar", as: filePath)
        AssertTrue(try await Storage.exists("foo/bar/\(filePath)"))
    }
    
    func testLocalPathing() async throws {
        try await Storage.create("foo/bar/baz/\(filePath)", content: "foo")
        AssertFalse(try await Storage.exists(filePath))
        AssertTrue(try await Storage.exists("foo/bar/baz/\(filePath)"))
        let file = try await Storage.get("foo/bar/baz/\(filePath)")
        AssertEqual(file.name, filePath)
        AssertEqual(try await file.getContent().collect(), ByteBuffer(string: "foo"))
        try await Storage.delete("foo/bar/baz/\(filePath)")
        AssertFalse(try await Storage.exists("foo/bar/baz/\(filePath)"))
    }
    
    func testLocalFileStore() async throws {
        try await File(name: filePath, source: .raw, content: "bar", size: 3).store(as: filePath)
        AssertTrue(try await Storage.exists(filePath))
    }
    
    func testLocalInvalidURL() async throws {
        do {
            let store: Filesystem = .local(root: "\\+https://www.apple.com")
            _ = try await store.exists("foo")
            XCTFail("Should throw an error")
        } catch {}
    }
}
