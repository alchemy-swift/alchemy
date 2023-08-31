import Alchemy

struct 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06Controller: Controller {
    func route(_ app: Application) {
        app
            .get("/673_a37ea-4b41-4dcb-b3be-b4b59c2a1d06", use: index)
            .post("/673_a37ea-4b41-4dcb-b3be-b4b59c2a1d06", use: create)
            .get("/673_a37ea-4b41-4dcb-b3be-b4b59c2a1d06/:id", use: show)
            .patch("/673_a37ea-4b41-4dcb-b3be-b4b59c2a1d06", use: update)
            .delete("/673_a37ea-4b41-4dcb-b3be-b4b59c2a1d06/:id", use: delete)
    }
    
    private func index(req: Request) async throws -> [673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06] {
        try await 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06.all()
    }
    
    private func create(req: Request) async throws -> 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06 {
        try await req.decode(673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06.self).insertReturn()
    }
    
    private func show(req: Request) async throws -> 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06 {
        try await 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06.find(req.parameter("id")).unwrap(or: HTTPError(.notFound))
    }
    
    private func update(req: Request) async throws -> 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06 {
        try await 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06.update(req.parameter("id"), with: req.body?.decodeJSONDictionary() ?? [:])
            .unwrap(or: HTTPError(.notFound))
    }
    
    private func delete(req: Request) async throws {
        try await 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06.delete(req.parameter("id"))
    }
}