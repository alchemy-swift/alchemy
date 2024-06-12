import Alchemy

/*
 
 GOAL: use macros to cut down on boilerplate
 
 Crush:
 0. dependencies / configuration
 1. routing
 2. middleware
 3. validation
 4. SQL access
 5. background work
 6. http
 7. testing
 8. logging / debugging
 
 Reduce
 1. number of types
 
 Repetitive Tasks
 - validate type and content
 - match database models
 - fire off jobs
 - multiple types verifying and mapping
 
 Foundational Tasks
 - map Request to function input
 - map output to Response
 - turn request fields into work based on function parameters
 
 Macros
 - CON: Need a top level macro to parse the body.
 - CON: Hard to gracefuly override
 - PRO: isolated
 - PRO: Composable
 - PRO: Easy overloads / hint what you want
 Closures
 - CON: can overload, but a lot of work

 */

@main
struct App: Application {
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

/*

@Routes
struct UserController {
    var middlewares: [Middleware] = [
        AuthMiddleware(),
        RateLimitMiddleware(),
        RequireUserMiddleware(),
        SanitizingMiddleware(),
    ]
    
    @GET("/users/:id")
    func getUser(user: User) async throws -> Fields {
        // fire off background work
        // access type from middleware
        // perform some arbitrary validation
        // hit 3rd party endpoint
        throw HTTPError(.notImplemented)
    }
    
    @POST("/users")
    func createUser(username: String, password: String) async throws -> Fields {
        User(username: username, password: password)
            .insertReturn()
            .without(\.password)
    }
    
    @PATCH("/users/:id")
    func updateUser(user: Int, name: String) async throws -> User {
        throw HTTPError(.notImplemented)
    }
    
    // MARK: Generated
    
    func _route(_ router: Router) {
        router
            .use(middlewares)
            .use(routes)
    }
    
    var routes: [Middleware.Handler] = [
        $createUser,
        $getUser,
        $updateUser,
    ]
    
    func _createUser(request: Request, next: Middleware.Next) async throws -> Response {
        guard request.method == .GET, request.path == "/users" else {
            return try await next(request)
        }
        
        let username = try request["username"].stringThrowing
        let password = try request["password"].stringThrowing
        let fields = createUser(username: username, password: password)
        return fields.response()
    }
}

@Model
struct User {
    var id: Int?
    let username: String
    let password: String
}
 
 */

/*
 
 Can I generate code that will run each time the app starts?
 
 - register commands
 - register macro'd jobs
 - register migrations
 - register macro'd routes
 - register service configuration (change app to class - should solve it)
 
 */
