@testable
import Alchemy
import AlchemyTest
import Testing

@Suite(.serialized)
struct FilesystemTests {
    private let app: TestApp
    private let filePath: String
    private let root: String

    init() async throws {
        self.app = try await .test()
        self.root = NSTemporaryDirectory() + UUID().uuidString
        self.filePath = UUID().uuidString + ".txt"
        let filesystem = Filesystem.local(root: root)
        Container.main.set(filesystem)
    }

    @Test func localRoot() {
        #expect(root == Storage.root)
    }

    @Test func localCreate() async throws {
        #expect(try await !Storage.exists(filePath))
        await #expect(throws: Error.self) { try await Storage.get(filePath) }
        try await Storage.create(filePath, content: "1;2;3")
        #expect(try await Storage.exists(filePath))
        let file = try await Storage.get(filePath)
        #expect(file.name == filePath)
        #expect(try await file.getContent().collect() == ByteBuffer(string: "1;2;3"))
    }

    @Test func localDelete() async throws {
        await #expect(throws: Error.self) { try await Storage.delete(filePath) }
        try await Storage.create(filePath, content: "123")
        try await Storage.delete(filePath)
        #expect(try await !Storage.exists(filePath))
    }

    @Test func localPut() async throws {
        let file = File(name: filePath, source: .raw, content: "foo", size: 3)
        try await Storage.put(file, as: filePath)
        #expect(try await Storage.exists(filePath))
        try await Storage.put(file, in: "foo/bar", as: filePath)
        #expect(try await Storage.exists("foo/bar/\(filePath)"))
    }

    @Test func localPathing() async throws {
        try await Storage.create("foo/bar/baz/\(filePath)", content: "foo")
        #expect(try await !Storage.exists(filePath))
        #expect(try await Storage.exists("foo/bar/baz/\(filePath)"))
        let file = try await Storage.get("foo/bar/baz/\(filePath)")
        #expect(file.name == filePath)
        #expect(try await file.getContent().collect() == ByteBuffer(string: "foo"))
        try await Storage.delete("foo/bar/baz/\(filePath)")
        #expect(try await !Storage.exists("foo/bar/baz/\(filePath)"))
    }

    @Test func localFileStore() async throws {
        try await File(name: filePath, source: .raw, content: "bar", size: 3).store(as: filePath)
        #expect(try await Storage.exists(filePath))
    }

    @Test func localInvalidURL() async throws {
        await #expect(throws: Error.self) {
            try await Filesystem
                .local(root: "\\+https://www.apple.com")
                .exists("foo")
        }
    }
}
