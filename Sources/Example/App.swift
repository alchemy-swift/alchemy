import Alchemy

struct App: Application {
    // The entrypoint of your application. Configure everything here.
    func setup() {
        // Setup jobs
        self.jobs()
        // Setup database & migrations
        self.database()
        // Setup routes
        self.route()
    }
    
    private func jobs() {
        Services.scheduler
            .every(2.hours, run: SampleJob())
            .every(1.days.at(hr: 18), run: NotifyUnfinishedTodos())
    }
    
    private func database() {
        // Set the default database for the app.
        Services.db = PostgresDatabase(
            config: DatabaseConfig(
                socket: .ip(
                    host: Env.DB_HOST!,
                    port: 5432
                ),
                database: Env.DB!,
                username: Env.DB_USERNAME!,
                password: Env.DB_PASSWORD!
            )
        )
        
        Services.db.migrations = [
            _20210107155059CreateUsers(),
            _20210107155107CreateTodos()
        ]
    }
    
    private func route() {
        self
            // Services static files from the "Public/" directory
            .useAll(StaticFileMiddleware())
            
            // Handles CORS preflights and headers
            .useAll(CORSMiddleware())
            
            // A simple api
            .get("/hello") { _ in
                "Hello, World!"
            }
            
            // A simple web page
            .get {
                HomeView(
                    greetings: ["Bonjour!", "¡Hola!", "Hallo!"],
                    name: $0.query(for: "name")
                )
            }
            
            // Controllers are abstractions around groups of routes.
            .controller(AuthController())
            
            // Protect subsequent routes in the chain behind token auth
            .use(UserToken.tokenAuthMiddleware())
            .controller(UsersController())
            .controller(TodoController())
    }
}
