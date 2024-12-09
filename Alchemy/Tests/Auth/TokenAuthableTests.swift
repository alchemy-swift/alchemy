@testable
import Alchemy
import AlchemyTesting

struct TokenAuthableTests: AppSuite {
    let app = TestApp()

    @Test func tokenAuthable() async throws {
        try await withApp { app in
            let db: Database = .memory
            try await db.migrate([AuthModel.Migrate(), TokenModel.Migrate()])

            // There's currently no easy way to override the database when fetching
            // relationships generated from macros.
            //
            // As such this needs to run on the global database. Would be great to
            // allow overriding so that this can run in isolation.
            Container.main.set(db)

            app
                .use(TokenModel.tokenAuthMiddleware(db: db))
                .get("/user") { req in
                    _ = try req.get(AuthModel.self)
                    return try req.get(TokenModel.self).value
                }

            print((Routes as! HTTPRouter).middlewares)

            let auth = try await AuthModel(email: "test@withapollo.com", password: Hash.make("password"))
                .insertReturn(on: db)
            let token = try await TokenModel(userId: auth.id)
                .insertReturn(on: db)

            let res1 = try await Test.get("/user")
            #expect(res1.status == .unauthorized)

            let res2 = try await Test.withToken(token.value.uuidString).get("/user")
            #expect(res2.status == .ok)
            #expect(try res2.decode() == token.value)

            let res3 = try await Test.withToken(UUID().uuidString).get("/user")
            #expect(res3.status == .unauthorized)
        }
    }
}
