@testable
import Alchemy
import AlchemyTest

final class GrammarTests: XCTestCase {
    private let grammar: SQLGrammar = PostgresGrammar()

    func testCompileSelect() {
        
    }
    
    func testCompileJoins() {
        
    }
    
    func testCompileWheres() {
        
    }
    
    func testCompileGroups() {
        XCTAssertEqual(grammar.compileGroups(["foo, bar, baz"]), "GROUP BY foo, bar, baz")
        XCTAssertEqual(grammar.compileGroups([]), nil)
    }
    
    func testCompileHavings() {
        
    }
    
    func testCompileOrders() {
        XCTAssertEqual(grammar.compileOrders([
            SQLOrder(column: "foo", direction: .asc),
            SQLOrder(column: "bar", direction: .desc)
        ]), "ORDER BY foo ASC, bar DESC")
        XCTAssertEqual(grammar.compileOrders([]), nil)
    }
    
    func testCompileLimit() {
        XCTAssertEqual(grammar.compileLimit(1), "LIMIT 1")
        XCTAssertEqual(grammar.compileLimit(nil), nil)
    }
    
    func testCompileOffset() {
        XCTAssertEqual(grammar.compileOffset(1), "OFFSET 1")
        XCTAssertEqual(grammar.compileOffset(nil), nil)
    }
    
    func testCompileInsert() {
        
    }
    
    func testCompileInsertAndReturn() {
        
    }
    
    func testCompileUpdate() {
        
    }
    
    func testCompileDelete() {
        
    }
    
    func testCompileLock() {
        XCTAssertEqual(grammar.compileLock(nil), nil)
        XCTAssertEqual(grammar.compileLock(SQLLock(strength: .update, option: nil)), "FOR UPDATE")
        XCTAssertEqual(grammar.compileLock(SQLLock(strength: .share, option: nil)), "FOR SHARE")
        XCTAssertEqual(grammar.compileLock(SQLLock(strength: .update, option: .skipLocked)), "FOR UPDATE SKIP LOCKED")
        XCTAssertEqual(grammar.compileLock(SQLLock(strength: .update, option: .noWait)), "FOR UPDATE NO WAIT")
    }
    
    func testCompileCreateTable() {
        
    }
    
    func testCompileRenameTable() {
        XCTAssertEqual(grammar.renameTable("foo", to: "bar"), """
        ALTER TABLE foo RENAME TO bar
        """)
    }
    
    func testCompileDropTable() {
        XCTAssertEqual(grammar.dropTable("foo"), """
        DROP TABLE foo
        """)
    }
    
    func testCompileAlterTable() {
        
    }
    
    func testCompileRenameColumn() {
        XCTAssertEqual(grammar.renameColumn(on: "foo", column: "bar", to: "baz"), """
        ALTER TABLE foo RENAME COLUMN "bar" TO "baz"
        """)
    }
    
    func testCompileCreateIndexes() {
        
    }
    
    func testCompileDropIndex() {
        XCTAssertEqual(grammar.dropIndex(on: "foo", indexName: "bar"), "DROP INDEX bar")
    }
    
    func testColumnTypeString() {
        XCTAssertEqual(grammar.columnTypeString(for: .increments), "serial")
        XCTAssertEqual(grammar.columnTypeString(for: .int), "int")
        XCTAssertEqual(grammar.columnTypeString(for: .bigInt), "bigint")
        XCTAssertEqual(grammar.columnTypeString(for: .double), "float8")
        XCTAssertEqual(grammar.columnTypeString(for: .string(.limit(10))), "varchar(10)")
        XCTAssertEqual(grammar.columnTypeString(for: .string(.unlimited)), "text")
        XCTAssertEqual(grammar.columnTypeString(for: .uuid), "uuid")
        XCTAssertEqual(grammar.columnTypeString(for: .bool), "bool")
        XCTAssertEqual(grammar.columnTypeString(for: .date), "timestamptz")
        XCTAssertEqual(grammar.columnTypeString(for: .json), "json")
    }
    
    func testCreateColumnString() {
        
    }
    
    func testJsonLiteral() {
        XCTAssertEqual(grammar.jsonLiteral(for: "foo"), "'foo'::jsonb")
    }
}
