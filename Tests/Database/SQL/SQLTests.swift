import Alchemy
import Testing

struct SQLTests {
    @Test func valueConvertible() {
        let sql: SQL = "NOW()"
        #expect(sql.rawSQLString == "NOW()")
    }

    @Test func joined() {
        #expect([
            SQL("where foo = ?", parameters: [.int(1)]),
            SQL("bar"),
            SQL("where baz = ?", parameters: [.string("two")])
        ].joined() == SQL("where foo = ? bar where baz = ?", parameters: [.int(1), .string("two")]))
    }
}
