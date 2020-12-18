/// A Postgres specific Grammar for compiling QueryBuilder statements into SQL
/// strings.
final class PostgresGrammar: Grammar {
    override func compileInsert(
        _ query: Query,
        values: [OrderedDictionary<String, Parameter>]
    ) throws -> SQL {
        var initial = try super.compileInsert(query, values: values)
        initial.query.append(" returning *")
        return initial
    }
}
