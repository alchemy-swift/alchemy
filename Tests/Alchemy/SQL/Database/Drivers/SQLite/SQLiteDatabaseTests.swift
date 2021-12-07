@testable
import Alchemy
import AlchemyTest

final class SQLiteDatabaseTests: TestCase<TestApp> {
    func testDatabase() throws {
        let memory = Database.memory
        guard memory.provider as? Alchemy.SQLiteDatabase != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        let path = Database.sqlite(path: "foo")
        guard path.provider as? Alchemy.SQLiteDatabase != nil else {
            XCTFail("The database provider should be SQLite.")
            return
        }
        
        try memory.shutdown()
        try path.shutdown()
    }
    
    func testConfigPath() throws {
        let provider = SQLiteDatabase(config: .file("foo"))
        XCTAssertEqual(provider.config, .file("foo"))
        try provider.shutdown()
    }
    
    func testConfigMemory() throws {
        let id = UUID().uuidString
        let provider = SQLiteDatabase(config: .memory(identifier: id))
        XCTAssertEqual(provider.config, .memory(identifier: id))
        try provider.shutdown()
    }
}
