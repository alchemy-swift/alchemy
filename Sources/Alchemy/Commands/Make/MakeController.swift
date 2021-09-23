import ArgumentParser

struct MakeController: Command {
    static var configuration = CommandConfiguration(
        commandName: "make:controller",
        discussion: "Create a new controller type"
    )
    
    @Argument var name: String
    
    @Option(name: .shortAndLong)
    var model: String?
    
    init() {}
    init(name: String = "", model: String? = nil) {
        self.name = name
        self.model = model
    }
    
    func start() -> EventLoopFuture<Void> {
        catchError {
            try createController()
            return .new()
        }
    }
    
    private func createController() throws {
        let template = model.map(modelControllerTemplate) ?? controllerTemplate()
        let fileName = model.map { "\($0)Controller" } ?? name
        try FileCreator.shared.create(fileName: "\(fileName)", contents: template, in: "Controllers")
    }
    
    private func controllerTemplate() -> String {
        return """
        import Alchemy

        struct \(name): Controller {
            func route(_ app: Application) {
                app.get("/index", handler: index)
            }
            
            private func index(req: Request) -> String {
                // write some code!
                return "Hello, world!"
            }
        }
        """
    }
    
    private func modelControllerTemplate(name: String) -> String {
        let resourcePath = name.camelCaseToSnakeCase()
        
        return """
        import Alchemy

        struct \(name)Controller: Controller {
            func route(_ app: Application) {
                app
                    .get("/\(resourcePath)", handler: index)
                    .post("/\(resourcePath)", handler: create)
                    .get("/\(resourcePath)/:id", handler: show)
                    .patch("/\(resourcePath)", handler: update)
                    .delete("/\(resourcePath)/:id", handler: delete)
            }
            
            private func index(req: Request) -> EventLoopFuture<[\(name)]> {
                \(name).all()
            }
            
            private func create(req: Request) throws -> EventLoopFuture<\(name)> {
                try req.decodeBody(as: \(name).self).insert()
            }
            
            private func show(req: Request) throws -> EventLoopFuture<\(name)> {
                \(name).find(try req.parameter("id"))
                    .unwrap(orError: HTTPError(.notFound))
            }
            
            private func update(req: Request) throws -> EventLoopFuture<\(name)> {
                \(name).update(try req.parameter("id"), with: try req.bodyDict())
                    .unwrap(orError: HTTPError(.notFound))
            }
            
            private func delete(req: Request) throws -> EventLoopFuture<Void> {
                \(name).delete(try req.parameter("id"))
            }
        }
        """
    }
}
