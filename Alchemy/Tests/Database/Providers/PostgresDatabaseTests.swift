@testable
import Alchemy
import AlchemyTesting
import NIOSSL

struct PostgresDatabaseTests {
    @Test func database() async throws {
        let db = Database.postgres(host: "127.0.0.1", database: "foo", username: "bar", password: "baz")
        guard let provider = db.provider as? Alchemy.PostgresDatabaseProvider else {
            Issue.record("The database provider should be PostgreSQL.")
            return
        }
        
        #expect(provider.pool.source.configuration.host == "127.0.0.1")
        #expect(provider.pool.source.configuration.port == 5432)
        #expect(provider.pool.source.configuration.database == "foo")
        #expect(provider.pool.source.configuration.username == "bar")
        #expect(provider.pool.source.configuration.password == "baz")

        try await db.shutdown()
    }

    @Test func positionBinds() {
        let query = "select * from cats where name = ? and age > ?"
        #expect(query.positionPostgresBinds() == "select * from cats where name = $1 and age > $2")
    }
}
