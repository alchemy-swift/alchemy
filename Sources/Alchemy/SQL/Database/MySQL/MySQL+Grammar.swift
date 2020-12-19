/// A MySQL specific Grammar for compiling QueryBuilder statements into SQL
/// strings.
final class MySQLGrammar: Grammar {
    override func compileInsert(
        _ query: Query,
        values: [OrderedDictionary<String, Parameter>]
    ) throws -> SQL {
        var initial = try super.compileInsert(query, values: values)
        initial.query.append("; select * from table where Id=LAST_INSERT_ID();")
        return initial
    }
}
