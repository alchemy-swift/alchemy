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

    func compileSelect(query: Query) -> SQL {

        // If the query does not have any columns set, we"ll set the columns to the
        // * character to just get all of the columns from the database. Then we
        // can build the query and concatenate all the pieces together as one.
        let original = query.columns

        if query.columns == nil {
            query.columns = ["*"]
        }

        // To compile the query, we'll spin through each component of the query and
        // see if that component exists. If it does we'll just call the compiler
        // function for the component which is responsible for making the SQL.
        let sql = compileComponents(query: query)

        query.columns = original

        return sql
    }

    private func compileComponents(query: Query) -> SQL
    {
        var sql: [String] = []
        var bindings: [Parameter] = []
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
                    let wheres = compileWheres(query).bind(&bindings)
                    sql.append(wheres.query)
                }
            }
        }
        return SQL(sql.joined(separator: " "), bindings: bindings)
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

    func compileJoins(_ query: Query, joins: [JoinClause]) -> SQL {
        var bindings: [Parameter] = []
        let query = joins.map { join in
            let whereSQL = compileWheres(join).bind(&bindings)
            if let nestedJoins = join.joins {
                let nestedSQL = compileJoins(query, joins: nestedJoins).bind(&bindings)
                return trim("\(join.type) join (\(join.table)\(nestedSQL.query)) \(whereSQL.query)")
            }
            return trim("\(join.type) join \(join.table) \(whereSQL.query)")
        }.joined(separator: " ")
        return SQL(query, bindings: bindings)
    }

    private func compileWheres(_ query: Query) -> SQL
    {

        // If we actually have some where clauses, we will strip off the first boolean
        // operator, which is added by the query builders for convenience so we can
        // avoid checking for the first clauses in each of the compilers methods.

        // Need to handle nested stuff somehow
        
        let (sql, bindings) = groupSQL(values: query.wheres)
        if (sql.count > 0) {
            let conjunction = query is JoinClause ? "on" : "where"
            let clauses = removeLeadingBoolean(sql.joined(separator: " "))
            return SQL("\(conjunction) \(clauses)", bindings: bindings)
        }
        return SQL()

        // This calls the where method based on the type of where that is passed in.
        // ie. whereBasic, whereColumn etc

//        return collect($query->wheres)->map(function ($where) use ($query) {
//            return $where['boolean'].' '.$this->{"where{$where['type']}"}($query, $where);
//        })->all();
    }








    func compileInsert(_ query: Query, values: [[String: Parameter]]) throws -> SQL
    {
        guard let table = query.from else { throw GrammarError.missingTable }

        if values.isEmpty {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].keys.joined(separator: ", ")
        let parameters = values.map { "(" + parameterize(Array($0.values)) + ")" }.joined(separator: ", ")
        return SQL("insert into \(table) (\(columns)) values (\(parameters))")
    }

    func compileUpdate(_ query: Query, values: [String: Parameter]) throws -> SQL
    {
        guard let table = query.from else { throw GrammarError.missingTable }
        var bindings: [Parameter] = []
        let columns = compileUpdateColumns(query, values: values)

        var base = "update \(table)"
        if let clauses = query.joins {
            let joinSQL = compileJoins(query, joins: clauses).bind(&bindings)
            base += " \(joinSQL)"
        }
        bindings += values.values
        let whereSQL = compileWheres(query).bind(&bindings)
        return SQL("\(base) set \(columns) \(whereSQL.query)", bindings: bindings)
    }

    func compileUpdateColumns(_ query: Query, values: [String: Parameter]) -> String {
        return values.map { "\($0) = \(parameter($1))" }.joined(separator: ", ")
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

    private func parameterize(_ values: [Parameter]) -> String
    {
        return values.map { parameter($0) }.joined(separator: ", ")
    }

    private func parameter(_ value: Parameter) -> String
    {
        return value is Expression ? value.description : "?"
    }

    private func trim(_ value: String) -> String
    {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
