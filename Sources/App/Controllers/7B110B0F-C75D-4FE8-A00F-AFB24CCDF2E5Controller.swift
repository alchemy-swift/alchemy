import Alchemy

struct 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5Controller: Controller {
    func route(_ app: Application) {
        app
            .get("/7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5", use: index)
            .post("/7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5", use: create)
            .get("/7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5/:id", use: show)
            .patch("/7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5", use: update)
            .delete("/7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5/:id", use: delete)
    }
    
    private func index(req: Request) async throws -> [7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5] {
        try await 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5.all()
    }
    
    private func create(req: Request) async throws -> 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5 {
        try await req.decode(7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5.self).insertReturn()
    }
    
    private func show(req: Request) async throws -> 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5 {
        try await 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5.find(req.parameter("id")).unwrap(or: HTTPError(.notFound))
    }
    
    private func update(req: Request) async throws -> 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5 {
        try await 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5.update(req.parameter("id"), with: req.body?.decodeJSONDictionary() ?? [:])
            .unwrap(or: HTTPError(.notFound))
    }
    
    private func delete(req: Request) async throws {
        try await 7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5.delete(req.parameter("id"))
    }
}