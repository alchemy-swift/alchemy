import ArgumentParser

struct MakeMiddleware: Command {
    static var logStartAndFinish: Bool = false
    static var configuration = CommandConfiguration(
        commandName: "make:middleware",
        discussion: "Create a new middleware type"
    )
    
    @Argument var name: String
    
    init() {}
    init(name: String) {
        self.name = name
    }
    
    func start() throws {
        try FileCreator.shared.create(fileName: name, contents: middlewareTemplate(), in: "Middleware")
    }
    
    private func middlewareTemplate() -> String {
        return """
        import Alchemy

        struct \(name): Middleware {
            func intercept(_ request: Request, next: Next) async throws -> Response {
                // Write some code!
                return try await next(request)
            }
        }
        """
    }
}
