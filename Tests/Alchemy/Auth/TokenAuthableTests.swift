import AlchemyTest

final class TokenAuthableTests: TestCase<TestApp> {
    func testTokenAuthable() async throws {
        Database.fake(migrations: [AuthModel.Migrate(), TokenModel.Migrate()])
        
        app.use(TokenModel.tokenAuthMiddleware())
        app.get("/user") { req -> UUID in
            _ = try req.get(AuthModel.self)
            return try req.get(TokenModel.self).value
        }
        
        let auth = try await AuthModel(email: "test@withapollo.com", password: Bcrypt.hash("password")).insertReturn()
        let token = try await TokenModel(authModel: auth).insertReturn()
        
        try await get("/user")
            .assertUnauthorized()
        
        try await withBearerAuth(token.value.uuidString)
            .get("/user")
            .assertOk()
            .assertJson(token.value)
        
        try await withBearerAuth(UUID().uuidString)
            .get("/user")
            .assertUnauthorized()
    }
}
