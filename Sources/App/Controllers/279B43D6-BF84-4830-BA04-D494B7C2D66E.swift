import Alchemy

struct 279B43D6-BF84-4830-BA04-D494B7C2D66E: Controller {
    func route(_ app: Application) {
        app.get("/index", use: index)
    }
    
    private func index(req: Request) -> String {
        // write some code!
        return "Hello, world!"
    }
}