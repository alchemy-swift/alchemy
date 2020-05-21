import Alchemy
import Foundation
import NIO

struct APIServer: Application {
    @Inject var postgres: PostgresDatabase
    @Inject(.one) var mySQL1: MySQLDatabase
    @Inject(.two) var mySQL2: MySQLDatabase
    @Inject var router: HTTPRouter
    @Inject var globalMiddlewares: GlobalMiddlewares
    
    func setup() {
        DB.default = self.postgres
        
        self.globalMiddlewares
            // Applied to all incoming requests.
            .add(LoggingMiddleware(text: "Received request:"))
        
        self.router
            // Applied to all subsequent routes
            .middleware(LoggingMiddleware(text: "Handling request:"))
            // `GET /json`
            .on(.GET, at: "/json", do: { _ in SampleJSON() })
            // Group all requests to /users
            .group(path: "/users") {
                $0.on(.POST, do: { req in "hi from create user" })
                    // `POST /users/reset`
                    .on(.POST, at: "/reset", do: { req in "hi from user reset" })
                    // Applies to the rest of the requests in this chain, giving them a `User` parameter.
                    .middleware(BasicAuthMiddleware<User>())
                    // `POST /users/login`
                    .on(.POST, at: "/login") { req, authedUser in "hi from user login" }
        }
            // Applies to requests in this group, validating a token auth and giving them a `User` parameter.
            .group(middleware: TokenAuthMiddleware<User>()) {
                // Applies to the rest of the requests in this chain.
                $0.path("/todo")
                    // `POST /todo`
                    .on(.POST) { req, user in "hi from todo create" }
                    // `PUT /todo`
                    .on(.POST) { req, user in "hi from todo update" }
                    // `DELETE /todo`
                    .on(.DELETE) { req, user in "hi from todo delete" }

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
                $0.on(.GET, at: "/delete", do: DatabaseTestController().delete)
                $0.on(.GET, at: "/join", do: DatabaseTestController().join)
            }
    }
}

struct MiscError: Error {
    private let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

struct DatabaseTestController {
    @Inject var db: PostgresDatabase
    
    func select(req: HTTPRequest) -> EventLoopFuture<[Trip]> {
        self.db.rawQuery("SELECT * FROM trips", on: req.eventLoop)
            .flatMapThrowing { try $0.map { try $0.decode(Trip.self) } }
    }
    
    func insert(req: HTTPRequest) throws -> EventLoopFuture<String> {
        let user = User(id: UUID())
        let place = Place(id: UUID())
        let flight = Flight(id: UUID())
        
        let trip = Trip(
            id: UUID(),
            flight: .init(to: flight),
            user: .init(user), // Property wrappers don't play nice with auto-generated initializers.
            origin: .init(place),
            destination: .init(place),
            priceStatus: .lowest,
            dotwStart: .friday,
            dotwEnd: .sunday,
            additionalWeeks: 0,
            outboundDepartureRange: nil,
            outboundDepartureTime: nil
        )
        
        let fields = try trip.fields()
        let columns = fields.map { $0.column }
        
        let statement = """
        insert into \(Trip.tableName) (\(columns.joined(separator: ", ")))
        values (\(fields.enumerated().map { index, _ in
            return "$\(index + 1)"
        }.joined(separator: ", ")))
        """
        
        print("statement: \(statement)")
        return self.db.query(statement, values: fields.map { $0.value }, on: req.eventLoop)
            .map { _ in "done" }
    }
    
    func update(req: HTTPRequest) -> EventLoopFuture<Trip> {
        fatalError("TODO")
        return self.db.rawQuery("SELECT * FROM trips", on: req.eventLoop)
            .flatMapThrowing { rows in
                guard let firstRow = rows.first else {
                    throw MiscError("No rows found.")
                }
                
                return try firstRow.decode(Trip.self)
        }
    }
    
    func delete(req: HTTPRequest) -> EventLoopFuture<Trip> {
        fatalError("TODO")
        return self.db.rawQuery("SELECT * FROM trips", on: req.eventLoop)
            .flatMapThrowing { rows in
                guard let firstRow = rows.first else {
                    throw MiscError("No rows found.")
                }
                
                return try firstRow.decode(Trip.self)
        }
    }
    
    func join(req: HTTPRequest) -> EventLoopFuture<Trip> {
        fatalError("TODO")
        return self.db.rawQuery("SELECT * FROM trips", on: req.eventLoop)
            .flatMapThrowing { rows in
                guard let firstRow = rows.first else {
                    throw MiscError("No rows found.")
                }
                
                return try firstRow.decode(Trip.self)
        }
    }
}

struct SampleJSON: Codable {
    let one = "value1"
    let two = "value2"
    let three = "value3"
    let four = 4
    let date = Date()
}

struct LoggingMiddleware: Middleware {
    let text: String
    
    func intercept(_ request: HTTPRequest) throws -> Void {
//        print("""
//            \(self.text)
//            METHOD: \(request.method)
//            PATH: \(request.path)
//            HEADERS: \(request.headers)
//            QUERY: \(request.queryItems)
//            BODY_STRING: \(request.body?.decodeString() ?? "N/A")
//            BODY_DICT: \(try request.body?.decodeJSONDictionary() ?? [:])
//            """)
    }
}
