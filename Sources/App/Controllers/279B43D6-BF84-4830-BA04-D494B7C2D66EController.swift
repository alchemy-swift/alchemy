import Alchemy

struct 279B43D6-BF84-4830-BA04-D494B7C2D66EController: Controller {
    func route(_ app: Application) {
        app
            .get("/279_b43d6-bf84-4830-ba04-d494b7c2d66e", use: index)
            .post("/279_b43d6-bf84-4830-ba04-d494b7c2d66e", use: create)
            .get("/279_b43d6-bf84-4830-ba04-d494b7c2d66e/:id", use: show)
            .patch("/279_b43d6-bf84-4830-ba04-d494b7c2d66e", use: update)
            .delete("/279_b43d6-bf84-4830-ba04-d494b7c2d66e/:id", use: delete)
    }
    
    private func index(req: Request) async throws -> [279B43D6-BF84-4830-BA04-D494B7C2D66E] {
        try await 279B43D6-BF84-4830-BA04-D494B7C2D66E.all()
    }
    
    private func create(req: Request) async throws -> 279B43D6-BF84-4830-BA04-D494B7C2D66E {
        try await req.decode(279B43D6-BF84-4830-BA04-D494B7C2D66E.self).insertReturn()
    }
    
    private func show(req: Request) async throws -> 279B43D6-BF84-4830-BA04-D494B7C2D66E {
        try await 279B43D6-BF84-4830-BA04-D494B7C2D66E.find(req.parameter("id")).unwrap(or: HTTPError(.notFound))
    }
    
    private func update(req: Request) async throws -> 279B43D6-BF84-4830-BA04-D494B7C2D66E {
        try await 279B43D6-BF84-4830-BA04-D494B7C2D66E.update(req.parameter("id"), with: req.body?.decodeJSONDictionary() ?? [:])
            .unwrap(or: HTTPError(.notFound))
    }
    
    private func delete(req: Request) async throws {
        try await 279B43D6-BF84-4830-BA04-D494B7C2D66E.delete(req.parameter("id"))
    }
}