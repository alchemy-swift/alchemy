import AlchemyTest

final class BasicAuthableTests: TestCase<TestApp> {
    func testBasicAuthable() async throws {
        Database.fake(migrations: [AuthModel.Migrate()])
        
        app.use(AuthModel.basicAuthMiddleware())
        app.get("/user") { try $0.get(AuthModel.self) }
        
        try await AuthModel(email: "test@withapollo.com", password: Bcrypt.hash("password")).insert()
        
        try await get("/user")
            .assertUnauthorized()
        
        try await withBasicAuth(username: "test@withapollo.com", password: "password")
            .get("/user")
            .assertOk()
        
        try await withBasicAuth(username: "test@withapollo.com", password: "foo")
            .get("/user")
            .assertUnauthorized()
        
        try await withBasicAuth(username: "josh@withapollo.com", password: "password")
            .get("/user")
            .assertUnauthorized()
    }
}
