import Alchemy

struct App: Application {
    // The entrypoint of your application. Configure everything here.
    func setup() {
        // Setup routes
        self.routes()
        // Setup database & migrations
        self.database()
        // Setup jobs
        self.jobs()
    }
    
    private func routes() {
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
                    greetings: ["Bonjour!", "Hola!", "Hallo!"],
                    name: $0.query(for: "name")
                )
            }
            
            // Controllers are abstractions around groups of routes.
            //
            // This function adds all routes added in the
            // `AuthController.route`.
            .controller(AuthController())
            
            // Protect subsequent routes in the chain behind token auth
            .use(UserToken.tokenAuthMiddleware())
            .controller(UsersController())
            .controller(TodoController())
    }
    
    private func database() {
        // Set the default database for the app.
        Services.db = PostgresDatabase(
            // Note that `Env` variables use here correspond to values
            // in the `.env` file in the main project directory.
            config: DatabaseConfig(
                socket: .ip(
                    // DB_HOST in `.env`
                    host: Env.DB_HOST!,
                    // DB_PORT in `.env`
                    port: Env.DB_PORT!
                ),
                // DB in `.env`
                database: Env.DB!,
                // DB_USER in `.env`
                username: Env.DB_USER!,
                // DB_PASSWORD in `.env`
                password: Env.DB_PASSWORD!
            )
        )
        
        // Add your migrations to their database. Note that this
        // doesn't actually run them yet. See the migrations
        // guide for more info.
        Services.db.migrations = [
            // Migrations begin with their creation timestamp so that
            // they can easily be applied in order.
            _20210107155059CreateUsers(),
            _20210107155107CreateTodos()
        ]
    }
    
    private func jobs() {
        // Scheduler schedules recurring jobs.
        Services.scheduler
            // `SampleJob` will run every 2 hours, starting on boot.
            .every(2.hours, run: SampleJob())
            // `OtherJob` will run every day at 18:00 (6 pm).
            .every(1.days.at(hr: 18), run: OtherJob())
    }
}
