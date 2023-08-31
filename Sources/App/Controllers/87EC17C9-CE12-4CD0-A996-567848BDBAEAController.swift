import Alchemy

struct 87EC17C9-CE12-4CD0-A996-567848BDBAEAController: Controller {
    func route(_ app: Application) {
        app
            .get("/87_ec17c9-ce12-4cd0-a996-567848bdbaea", use: index)
            .post("/87_ec17c9-ce12-4cd0-a996-567848bdbaea", use: create)
            .get("/87_ec17c9-ce12-4cd0-a996-567848bdbaea/:id", use: show)
            .patch("/87_ec17c9-ce12-4cd0-a996-567848bdbaea", use: update)
            .delete("/87_ec17c9-ce12-4cd0-a996-567848bdbaea/:id", use: delete)
    }
    
    private func index(req: Request) async throws -> [87EC17C9-CE12-4CD0-A996-567848BDBAEA] {
        try await 87EC17C9-CE12-4CD0-A996-567848BDBAEA.all()
    }
    
    private func create(req: Request) async throws -> 87EC17C9-CE12-4CD0-A996-567848BDBAEA {
        try await req.decode(87EC17C9-CE12-4CD0-A996-567848BDBAEA.self).insertReturn()
    }
    
    private func show(req: Request) async throws -> 87EC17C9-CE12-4CD0-A996-567848BDBAEA {
        try await 87EC17C9-CE12-4CD0-A996-567848BDBAEA.find(req.parameter("id")).unwrap(or: HTTPError(.notFound))
    }
    
    private func update(req: Request) async throws -> 87EC17C9-CE12-4CD0-A996-567848BDBAEA {
        try await 87EC17C9-CE12-4CD0-A996-567848BDBAEA.update(req.parameter("id"), with: req.body?.decodeJSONDictionary() ?? [:])
            .unwrap(or: HTTPError(.notFound))
    }
    
    private func delete(req: Request) async throws {
        try await 87EC17C9-CE12-4CD0-A996-567848BDBAEA.delete(req.parameter("id"))
    }
}