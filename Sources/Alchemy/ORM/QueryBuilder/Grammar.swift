import Foundation

class Grammar {

    enum GrammarError: Error {
        case missingTable
    }

    private let selectComponents: [AnyKeyPath] = [
        \Query.columns,
        \Query.from,
        \Query.joins,
        \Query.wheres,
        \Query.groups,
        \Query.havings,
        \Query.orders,
        \Query.limit,
        \Query.offset
    ]

    func compileSelect(query: Query) -> String {

        // If the query does not have any columns set, we"ll set the columns to the
        // * character to just get all of the columns from the database. Then we
        // can build the query and concatenate all the pieces together as one.
        let original = query.columns

        if query.columns == nil {
            query.columns = ["*"]
        }

        // To compile the query, we"ll spin through each component of the query and
        // see if that component exists. If it does we"ll just call the compiler
        // function for the component which is responsible for making the SQL.
        let sql = concatenate(compileComponents(query: query))

        query.columns = original;

        return sql
    }

    private func compileComponents(query: Query) -> [String]
    {
        var sql: [String] = [];
        for component in selectComponents {
            // To compile the query, well spin through each component of the query and
            // see if that component exists. If it does we"ll just call the compiler
            // function for the component which is responsible for making the SQL.
            if let part = query[keyPath: component] {
                if component == \Query.columns, let columns = part as? [String] {
                    sql.append(compileColumns(query, columns: columns))
                }
                else if component == \Query.from, let table = part as? String {
                    sql.append(compileFrom(query, table: table))
                }
                else if component == \Query.wheres {
                    sql.append(compileWheres(query))
                }
            }
        }
        return sql
    }

    private func compileColumns(_ query: Query, columns: [String]) -> String
    {
        let select = query.distinct ? "select distinct" : "select"
        return "\(select) \(columns.joined(separator: ", "))"
    }

    private func compileFrom(_ query: Query, table: String) -> String
    {
        return "from \(table)"
    }

    func compileJoins(_ query: Query, joins: [JoinClause]) -> String {

        return joins.map { join in
            let compiledWhere = compileWheres(join)
            if let nestedJoins = join.joins {
                let compiledNested = compileJoins(query, joins: nestedJoins)
                return trim("\(join.type) join (\(join.table)\(compiledNested)) \(compiledWhere)")
            }
            return trim("\(join.type) join \(join.table) \(compiledWhere)")
        }.joined(separator: " ")
    }

    private func compileWheres(_ query: Query) -> String
    {

        // If we actually have some where clauses, we will strip off the first boolean
        // operator, which is added by the query builders for convenience so we can
        // avoid checking for the first clauses in each of the compilers methods.

        // Need to handle nested stuff somehow
        var parts = query.wheres.map { $0.toString() }
        if (parts.count > 0) {
            let conjunction = query is JoinClause ? "on" : "where"
            let clauses = removeLeadingBoolean(parts.joined(separator: " "))
            return "\(conjunction) \(clauses)"
        }
        return ""

        // This calls the where method based on the type of where that is passed in.
        // ie. whereBasic, whereColumn etc

//        return collect($query->wheres)->map(function ($where) use ($query) {
//            return $where['boolean'].' '.$this->{"where{$where['type']}"}($query, $where);
//        })->all();
    }

    private func whereIn(_ query: Query, where: [WhereClause]) {

    }









    func compileInsert(_ query: Query, values: [String: Clause]) throws -> String
    {
        guard let table = query.from else { throw GrammarError.missingTable }

        if values.isEmpty {
            return "insert into \(table) default values"
        }

        let columns = values.keys.joined(separator: ", ")
        let parameters = parameterize(values.values.map { $0 })

        return "insert into \(table) (\(columns)) values (\(parameters))"
    }

    func compileUpdate(_ query: Query, values: [Clause]) throws -> String
    {
        guard let table = query.from else { throw GrammarError.missingTable }
        let columns = compileUpdateColumns(query, values: values)
        let wheres = compileWheres(query)

        if let clauses = query.joins {
            let joins = compileJoins(query, joins: clauses)
            return "update \(table) \(joins) set \(columns) \(wheres)"
        }
        return "update \(table) set \(columns) \(wheres)"
    }

    func compileUpdateColumns(_ query: Query, values: [Clause]) -> String {
        return values.enumerated().map { "\($0) = \(parameter($1))" }.joined(separator: ", ")
    }






    private func removeLeadingBoolean(_ value: String) -> String
    {
        if value.hasPrefix("and ") {
            return String(value.dropFirst(4))
        }
        else if value.hasPrefix("or ") {
            return String(value.dropFirst(3))
        }
        return value
    }

    private func concatenate(_ segments: [String]) -> String
    {
        return segments.filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func parameterize(_ values: [Clause]) -> String
    {
        return values.map { parameter($0) }.joined(separator: ", ")
    }

    private func parameter(_ value: Clause) -> String
    {
        return value is Expression ? value.toString() : "?"
    }

    private func trim(_ value: String) -> String
    {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
