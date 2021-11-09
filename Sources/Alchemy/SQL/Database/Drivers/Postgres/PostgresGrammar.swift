import OrderedCollections

/// A Postgres specific Grammar for compiling QueryBuilder statements
/// into SQL strings.
final class PostgresGrammar: Grammar {
    override func compileInsert(_ query: Query, values: [OrderedDictionary<String, SQLValueConvertible>]) throws -> SQL {
        let initial = try super.compileInsert(query, values: values)
        return SQL(initial.query + " returning *", bindings: initial.bindings)
    }
}
