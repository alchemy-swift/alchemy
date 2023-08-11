import AlchemyTest

final class TokenAuthableTests: TestCase<TestApp> {
    func testTokenAuthable() async throws {
        try await Database.fake(migrations: [AuthModel.Migrate(), TokenModel.Migrate()])
        
        app.use(TokenModel.tokenAuthMiddleware())
        app.get("/user") { req -> UUID in
            _ = try req.get(AuthModel.self)
            return try req.get(TokenModel.self).value
        }
        
        let auth = try await AuthModel(email: "test@withapollo.com", password: Hash.make("password")).insertReturn()
        let token = try await TokenModel(userId: auth.id.require()).insertReturn()
        
        try await Test.get("/user")
            .assertUnauthorized()
        
        try await Test.withToken(token.value.uuidString)
            .get("/user")
            .assertOk()
            .assertJson(token.value)
        
        try await Test.withToken(UUID().uuidString)
            .get("/user")
            .assertUnauthorized()
    }
}
