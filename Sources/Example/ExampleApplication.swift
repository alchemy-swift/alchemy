import Alchemy
import Foundation
import NIO

struct ExampleApplication: Application {
    @Inject var router: Router
    
    func setup() {
        Log.info("Hello from setup.")
        
        // Register global database
        Container.global.register(singleton: Database.self) { _ in
            PostgresDatabase(config: .postgres)
        }
        
        var database = Container.global.resolve(Database.self)
        
        DB.default = database
        
        // Applied to all incoming requests.
        self.router.globalMiddlewares = [
            LoggingMiddleware(text: "First."),
            LoggingMiddleware(text: "Second."),
            LoggingMiddleware(text: "Third.")
        ]
        
        self.router
            // `GET /json`
            .on(.GET, at: "/json", do: { _ in SampleJSON() })
            // Group all pet requests
            .group(path: "/pets") {
                let controller = PetsController()
                $0.on(.POST, at: "/owner", do: controller.createOwner)
                $0.on(.GET, at: "/owner", do: controller.getOwners)
                $0.on(.POST, at: "/pet", do: controller.createPet)
                $0.on(.GET, at: "/pet", do: controller.getPets)
                $0.on(.GET, at: "/license", do: controller.createLicense)
                $0.on(.POST, at: "/vaccinate/:pet_id/:vaccine_id", do: controller.vaccinate)
            }
            // Group all requests to /users
            .group(path: "/users") {
                $0.on(.POST, do: { req in "hi from create user" })
                    // `POST /users/reset`
                    .on(.POST, at: "/reset", do: { req in "hi from user reset" })
                    // Applies to the rest of the requests in this chain, giving them a `User` parameter.
                    .middleware(User.basicAuthMiddleware())
                    // `POST /users/login`
                    .on(.POST, at: "/login") { req in "hi from user login" }
            }
            // Applies to requests in this group, validating a token auth and giving them a `User` parameter.
            .group(middleware: UserToken.tokenAuthMiddleware()) {
                // Applies to the rest of the requests in this chain.
                $0.path("/todo")
                    // `POST /todo`
                    .on(.POST) { req in "hi from todo create" }
                    // `PUT /todo`
                    .on(.POST) { req in "hi from todo update" }
                    // `DELETE /todo`
                    .on(.DELETE) { req in "hi from todo delete" }

                // Abstraction for handling requests related to friends.
                let friends = FriendsController()

                // Applies to the rest of the requests in this chain.
                $0.path("/friends")
                    // `POST /friends`
                    .on(.POST, do: friends.message)
                    // `DELETE /friends`
                    .on(.DELETE, do: friends.remove)
                    // `POST /friends/message`
                    .on(.POST, at: "/message", do: friends.message)
            }
            .group(path: "/db") {
                $0.on(.GET, at: "/select", do: DatabaseTestController().select)
                $0.on(.GET, at: "/insert", do: DatabaseTestController().insert)
                $0.on(.GET, at: "/update", do: DatabaseTestController().update)
            }
        
        database.migrations
            .append(contentsOf: [
                _20201229164212CreatePets(),
            ])

        _ = database.migrate()
    }
}

struct MiscError: Error {
    private let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

struct Testing: Codable {
    var age = 28
    var name = "Joshua"
}

struct DatabaseTestController {
    @Inject var db: MySQLDatabase
    
    func update(req: Request) throws -> EventLoopFuture<Void> {
        try User.query()
            .where("id" == UUID(uuidString: "95dd20ec-c151-4dcd-8f86-364b99631aa8"))
            .update(values: ["some_json": DatabaseValue.json(nil)])
            .voided()
    }
    
    func select(req: Request) -> EventLoopFuture<Int?> {
        Rental.query()
            .where("num_beds" >= 1)
            .count(as: "rentals_count")
    }
    
    func insert(req: Request) throws -> EventLoopFuture<String> {
        Rental.query(database: self.db)
            .insert([
                [
                    "price": 220,
                    "num_beds": 1,
                    "location": "NYC"
                ],
                [
                    "price": 100,
                    "num_beds": 7,
                    "location": "Dallas"
                ]
            ])
            .map { _ in "done" }
    }
}

struct SampleJSON: Codable {
    var one = "value1"
    var two = "value2"
    var three = "value3"
    var four = 4
    var date = Date()
}

struct LoggingMiddleware: Middleware {
    let text: String
    
    func intercept(_ request: Request, next: @escaping Next) -> EventLoopFuture<Response> {
        Log.info(self.text)
        return next(request)
            .map {
                Log.info(self.text)
                return $0
            }
    }
}

struct TestingInject {
    @Inject
    var string: String
}
