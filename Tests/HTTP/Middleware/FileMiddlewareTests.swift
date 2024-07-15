@testable
import Alchemy
import AlchemyTest

final class FileMiddlewareTests: TestCase<TestApp> {
    var middleware: FileMiddleware!
    var fileName = UUID().uuidString
    
    override func setUp() {
        super.setUp()
        FileCreator.mock()
        middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public", extensions: ["html"])
        fileName = UUID().uuidString
    }
    
    func testDirectorySanitize() async throws {
        middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public/", extensions: ["html"])
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")

        try await middleware
            .handle(.get(fileName), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .handle(.get("//////\(fileName)"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        do {
            _ = try await middleware.handle(.get("../foo"), next: { _ in .default })
            XCTFail("An error should be thrown")
        } catch {}
    }
    
    func testGetOnly() async throws {
        try await middleware
            .handle(.post(fileName), next: { _ in .default })
            .assertBody("bar")
    }
    
    func testRedirectIndex() async throws {
        try FileCreator.shared.create(fileName: "index", extension: "html", contents: "foo;bar;baz", in: "Public")
        try await middleware
            .handle(.get(""), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
    }
    
    func testLoadingFile() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "txt", contents: "foo;bar;baz", in: "Public")
        
        try await middleware
            .handle(.get("\(fileName).txt"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .handle(.get(fileName), next: { _ in .default })
            .assertBody("bar")
    }
    
    func testLoadingAlternateExtension() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")
        
        try await middleware
            .handle(.get(fileName), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .handle(.get("\(fileName).html"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
    }
}

extension Request {
    fileprivate static func get(_ uri: String) -> Request {
        .fake(method: .get, uri: uri)
    }
    
    fileprivate static func post(_ uri: String) -> Request {
        .fake(method: .post, uri: uri)
    }
}

extension Response {
    static let `default` = Response(status: .ok, string: "bar")
}
