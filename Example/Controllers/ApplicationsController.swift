import Alchemy

struct ApplicationsController: Controller {
    func route(_ router: Router) {
        router
            .get("/applications", use: index)
            .post("/applications", use: create)
            .get("/applications/:id", use: show)
            .patch("/applications", use: update)
            .delete("/applications/:id", use: delete)
    }
    
    private func index(req: Request) async throws -> [Applications] {
        try await Applications.all()
    }
    
    private func create(req: Request) async throws -> Applications {
        try await req.decode(Applications.self).insertReturn()
    }
    
    private func show(req: Request) async throws -> Applications {
        try await Applications.require(req.requireParameter("id"))
    }
    
    private func update(req: Request) async throws -> Applications {
        try await Applications.require(req.requireParameter("id")).update(req.content)
    }
    
    private func delete(req: Request) async throws {
        try await Applications.delete(req.requireParameter("id"))
    }
}
