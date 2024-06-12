import Alchemy

@Application
struct App {
    func boot() throws {
        get("/200", use: get200)
        get("/400", use: get400)
        get("/500", use: get500)
    }
    
    func get200(req: Request) {}
    func get400(req: Request) throws { throw HTTPError(.badRequest) }
    func get500(req: Request) throws { throw HTTPError(.internalServerError) }

    @Job
    static func expensive() async throws {
        print("Hello")
    }
}
