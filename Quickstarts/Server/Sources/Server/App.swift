import Alchemy

struct App: Application {
    // The entrypoint of your application. Configure routers, database here.
    func setup() {
        // Setup database & migrations
        // Setup jobs
        // Configure routes
        Services.router
            .on(.GET) { _ in
                "Hello, World!"
            }
            .controller(UsersController())
    }
}

struct UsersController: Controller {
    func route(_ router: Router) {
        router.on(.GET, at: "/lol") { request in
            
        }
    }
}
