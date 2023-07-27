/// A Postgres specific Grammar for compiling QueryBuilder statements into SQL
/// strings. The base Grammar class is made for Postgres, so there isn't
/// anything to override at the moment.
final class PostgresGrammar: Grammar {}
struct PostgresDialect: SQLDialect {
    let grammar: Grammar = PostgresGrammar()
}
