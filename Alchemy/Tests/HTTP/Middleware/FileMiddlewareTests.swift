@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct FileMiddlewareTests: TestSuite {
    let middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public", extensions: ["html"])
    let fileName = UUID().uuidString

    init() {
        FileCreator.mock()
    }

    @Test func directorySanitize() async throws {
        let middleware = FileMiddleware(from: FileCreator.shared.rootPath + "Public/", extensions: ["html"])
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")

        let res1 = try await middleware
            .handle(.get(fileName), next: { _ in .default })
            .collect()
        #expect(res1.body?.string == "foo;bar;baz")

        let res2 = try await middleware
            .handle(.get("//////\(fileName)"), next: { _ in .default })
            .collect()
        #expect(res2.body?.string == "foo;bar;baz")

        await #expect(throws: Error.self) {
            try await middleware.handle(.get("../foo"), next: { _ in .default })
        }
    }
    
    @Test func getOnly() async throws {
        let res = try await middleware.handle(.post(fileName), next: { _ in .default })
        #expect(res.body?.string == "bar")
    }
    
    @Test func redirectIndex() async throws {
        try FileCreator.shared.create(fileName: "index", extension: "html", contents: "foo;bar;baz", in: "Public")
        let res = try await middleware
            .handle(.get(""), next: { _ in .default })
            .collect()
        #expect(res.body?.string == "foo;bar;baz")
    }
    
    @Test func loadingFile() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "txt", contents: "foo;bar;baz", in: "Public")
        
        let res1 = try await middleware
            .handle(.get("\(fileName).txt"), next: { _ in .default })
            .collect()
        #expect(res1.body?.string == "foo;bar;baz")

        let res2 = try await middleware.handle(.get(fileName), next: { _ in .default })
        #expect(res2.body?.string == "bar")
    }
    
    @Test func loadingAlternateExtension() async throws {
        try FileCreator.shared.create(fileName: fileName, extension: "html", contents: "foo;bar;baz", in: "Public")
        
        let res1 = try await middleware
            .handle(.get(fileName), next: { _ in .default })
            .collect()
        #expect(res1.body?.string == "foo;bar;baz")

        let res2 = try await middleware
            .handle(.get("\(fileName).html"), next: { _ in .default })
            .collect()
        #expect(res2.body?.string == "foo;bar;baz")
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
