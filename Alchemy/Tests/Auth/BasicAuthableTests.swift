@testable
import Alchemy
import AlchemyTesting
import NIO

@Suite(.mockContainer)
struct BasicAuthableTests: TestSuite {
    @Test func basicAuthable() async throws {
        let db = Database.memory
        try await db.migrate([AuthModel.Migrate()])

        App
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
