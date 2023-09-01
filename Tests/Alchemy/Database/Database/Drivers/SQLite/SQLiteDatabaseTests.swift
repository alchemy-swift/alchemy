@testable
import Alchemy
import AlchemyTest

final class SQLiteDatabaseTests: TestCase<TestApp> {
    func testDatabase() async throws {
        let memory = Database.memory
        guard memory.provider as? Alchemy.SQLiteDatabaseProvider != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        let path = Database.sqlite(path: "foo")
        guard path.provider as? Alchemy.SQLiteDatabaseProvider != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        try await memory.shutdown()
        try await path.shutdown()
    }
}
