/// A Postgres specific Grammar for compiling QueryBuilder statements
/// into SQL strings.
final class PostgresGrammar: Grammar {
    override func compileInsert(_ table: String, values: [[String: SQLValueConvertible]]) throws -> SQL {
        let initial = try super.compileInsert(table, values: values)
        return SQL(initial.statement + " returning *", bindings: initial.bindings)
    }
}
