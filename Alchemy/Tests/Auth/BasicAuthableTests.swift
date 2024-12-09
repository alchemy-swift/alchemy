@testable
import Alchemy
import AlchemyTesting
import NIO

struct BasicAuthableTests: AppSuite {
    let app = TestApp()

    @Test func basicAuthable() async throws {
        try await withApp { app in
            let db = Database.memory
            try await db.migrate([AuthModel.Migrate()])

            app
                .use(AuthModel.basicAuthMiddleware(db: db))
                .get("/user") { try $0.get(AuthModel.self) }

            try await AuthModel(email: "test@withapollo.com", password: Hash.make("password"))
                .insert(on: db)

            let res1 = try await Test.get("/user")
            #expect(res1.status == .unauthorized)

            let res2 = try await Test.withBasicAuth(username: "test@withapollo.com", password: "password").get("/user")
            #expect(res2.status == .ok)

            let res3 = try await Test.withBasicAuth(username: "test@withapollo.com", password: "foo").get("/user")
            #expect(res3.status == .unauthorized)

            let res4 = try await Test.withBasicAuth(username: "josh@withapollo.com", password: "password").get("/user")
            #expect(res4.status == .unauthorized)
        }
    }
}
