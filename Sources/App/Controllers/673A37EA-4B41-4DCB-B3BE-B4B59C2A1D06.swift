import Alchemy

struct 673A37EA-4B41-4DCB-B3BE-B4B59C2A1D06: Controller {
    func route(_ app: Application) {
        app.get("/index", use: index)
    }
    
    private func index(req: Request) -> String {
        // write some code!
        return "Hello, world!"
    }
}