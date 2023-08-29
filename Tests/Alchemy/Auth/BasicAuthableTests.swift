//import AlchemyTest
//
//final class BasicAuthableTests: TestCase<TestApp> {
//    func testBasicAuthable() async throws {
//        try await Database.fake(migrations: [AuthModel.Migrate()])
//        
//        app.use(AuthModel.basicAuthMiddleware())
//        app.get("/user") { try $0.get(AuthModel.self) }
//        
//        try await AuthModel(email: "test@withapollo.com", password: Hash.make("password")).insert()
//        
//        try await Test.get("/user")
//            .assertUnauthorized()
//        
//        try await Test.withBasicAuth(username: "test@withapollo.com", password: "password")
//            .get("/user")
//            .assertOk()
//        
//        try await Test.withBasicAuth(username: "test@withapollo.com", password: "foo")
//            .get("/user")
//            .assertUnauthorized()
//        
//        try await Test.withBasicAuth(username: "josh@withapollo.com", password: "password")
//            .get("/user")
//            .assertUnauthorized()
//    }
//}
