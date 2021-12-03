@testable
import Alchemy
import AlchemyTest

final class FileMiddlewareTests: TestCase<TestApp> {
    var middleware: FileMiddleware!
    var fileName = UUID().uuidString
    
    override func setUp() {
        super.setUp()
        middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public", extensions: ["html"])
        fileName = UUID().uuidString
    }
    
    func testDirectorySanitize() async throws {
        middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public/", extensions: ["html"])
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")
        
        try await middleware
            .intercept(.get(fileName), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .intercept(.get("//////\(fileName)"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        do {
            _ = try await middleware.intercept(.get("../foo"), next: { _ in .default })
            XCTFail("An error should be thrown")
        } catch {}
    }
    
    func testGetOnly() async throws {
        try await middleware
            .intercept(.post(fileName), next: { _ in .default })
            .assertBody("bar")
    }
    
    func testRedirectIndex() async throws {
        try FileCreator.shared.create(fileName: "index", extension: "html", contents: "foo;bar;baz", in: "Public")
        try await middleware
            .intercept(.get(""), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
    }
    
    func testLoadingFile() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "txt", contents: "foo;bar;baz", in: "Public")
        
        try await middleware
            .intercept(.get("\(fileName).txt"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .intercept(.get(fileName), next: { _ in .default })
            .assertBody("bar")
    }
    
    func testLoadingAlternateExtension() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")
        
        try await middleware
            .intercept(.get(fileName), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
        
        try await middleware
            .intercept(.get("\(fileName).html"), next: { _ in .default })
            .collect()
            .assertBody("foo;bar;baz")
    }
}

extension Request {
    static func get(_ uri: String) -> Request {
        Request(head: .init(version: .http1_1, method: .GET, uri: uri), remoteAddress: nil)
    }
    
    static func post(_ uri: String) -> Request {
        Request(head: .init(version: .http1_1, method: .POST, uri: uri), remoteAddress: nil)
    }
}

extension Response {
    static let `default` = Response(status: .ok).withString("bar")
}
