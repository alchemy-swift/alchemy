@testable
import Alchemy
import AlchemyTest

final class SQLiteDatabaseTests: TestCase<TestApp> {
    func testDatabase() throws {
        let memory = Database.memory
        guard memory.driver as? Alchemy.SQLiteDatabase != nil else {
            XCTFail("The database driver should be SQLite.")
            return
        }
        
        let path = Database.sqlite(path: "foo")
        guard path.driver as? Alchemy.SQLiteDatabase != nil else {
            XCTFail("The database driver should be SQLite.")
            return
        }
        
        try memory.shutdown()
        try path.shutdown()
    }
    
    func testConfigPath() throws {
        let driver = SQLiteDatabase(config: .file("foo"))
        XCTAssertEqual(driver.config, .file("foo"))
        try driver.shutdown()
    }
    
    func testConfigMemory() throws {
        let driver = SQLiteDatabase(config: .memory)
        XCTAssertEqual(driver.config, .memory)
        try driver.shutdown()
    }
}
