@testable
import Alchemy
import Testing

struct SQLGrammarTests {
    private let grammar: SQLGrammar = PostgresGrammar()

    @Test func select() {

    }
    
    @Test func joins() {

    }
    
    @Test func wheres() {

    }
    
    @Test func groups() {
        #expect(grammar.compileGroups(["foo, bar, baz"]) == "GROUP BY foo, bar, baz")
        #expect(grammar.compileGroups([]) == nil)
    }
    
    @Test func havings() {

    }
    
    @Test func orders() {
        #expect(grammar.compileOrders([
            SQLOrder(column: "foo", direction: .asc),
            SQLOrder(column: "bar", direction: .desc)
        ]) == "ORDER BY foo ASC, bar DESC")
        #expect(grammar.compileOrders([]) == nil)
    }
    
    @Test func limit() {
        #expect(grammar.compileLimit(1) == "LIMIT 1")
        #expect(grammar.compileLimit(nil) == nil)
    }
    
    @Test func offset() {
        #expect(grammar.compileOffset(1) == "OFFSET 1")
        #expect(grammar.compileOffset(nil) == nil)
    }
    
    @Test func insert() {

    }
    
    @Test func insertAndReturn() {

    }
    
    @Test func update() {

    }
    
    @Test func delete() {

    }
    
    @Test func lock() {
        #expect(grammar.compileLock(nil) == nil)
        #expect(grammar.compileLock(SQLLock(strength: .update, option: nil)) == "FOR UPDATE")
        #expect(grammar.compileLock(SQLLock(strength: .share, option: nil)) == "FOR SHARE")
        #expect(grammar.compileLock(SQLLock(strength: .update, option: .skipLocked)) == "FOR UPDATE SKIP LOCKED")
        #expect(grammar.compileLock(SQLLock(strength: .update, option: .noWait)) == "FOR UPDATE NO WAIT")
    }
    
    @Test func createTable() {

    }
    
    @Test func renameTable() {
        #expect(grammar.renameTable("foo", to: "bar") == """
        ALTER TABLE foo RENAME TO bar
        """)
    }
    
    @Test func dropTable() {
        #expect(grammar.dropTable("foo") == """
        DROP TABLE foo
        """)
    }
    
    @Test func alterTable() {

    }
    
    @Test func renameColumn() {
        #expect(grammar.renameColumn(on: "foo", column: "bar", to: "baz") == """
        ALTER TABLE foo RENAME COLUMN "bar" TO "baz"
        """)
    }

    @Test func createIndexes() {

    }
    
    @Test func dropIndex() {
        #expect(grammar.dropIndex(on: "foo", indexName: "bar") == "DROP INDEX bar")
    }
    
    @Test func columnTypeString() {
        #expect(grammar.columnTypeString(for: .increments) == "serial")
        #expect(grammar.columnTypeString(for: .int) == "int")
        #expect(grammar.columnTypeString(for: .bigInt) == "bigint")
        #expect(grammar.columnTypeString(for: .double) == "float8")
        #expect(grammar.columnTypeString(for: .string(.limit(10))) == "varchar(10)")
        #expect(grammar.columnTypeString(for: .string(.unlimited)) == "text")
        #expect(grammar.columnTypeString(for: .uuid) == "uuid")
        #expect(grammar.columnTypeString(for: .bool) == "bool")
        #expect(grammar.columnTypeString(for: .date) == "timestamptz")
        #expect(grammar.columnTypeString(for: .json) == "json")
    }
    
    @Test func createColumnString() {

    }
    
    @Test func jsonLiteral() {
        #expect(grammar.jsonLiteral(for: "foo") == "'foo'::jsonb")
    }
}
