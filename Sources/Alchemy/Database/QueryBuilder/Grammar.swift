import Foundation

public class Grammar {

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

        // If the query does not have any columns set, we'll set the columns to the
        // * character to just get all of the columns from the database. Then we
        // can build the query and concatenate all the pieces together as one.
        let original = query.columns

        if query.columns == nil {
            query.columns = [SQL("*")]
        }

        // To compile the query, we'll spin through each component of the query and
        // see if that component exists. If it does we'll just call the compiler
        // function for the component which is responsible for making the SQL.
        let sql = compileComponents(query: query)

        query.columns = original

        return sql
    }

    private func compileComponents(query: Query) -> SQL {
        var sql: [String] = []
        var bindings: [DatabaseValue] = []

        for component in selectComponents {
            if let part = query[keyPath: component] {
                if component == \Query.columns,
                    let columns = part as? [Raw] {
                    compileColumns(query, columns: columns)
                        .bind(queries: &sql, bindings: &bindings)
                }
                else if component == \Query.from,
                    let table = part as? String {
                    sql.append(compileFrom(query, table: table))
                }
                else if component == \Query.joins,
                    let joins = part as? [JoinClause] {
                    compileJoins(query, joins: joins)
                        .bind(queries: &sql, bindings: &bindings)
                }
                else if component == \Query.wheres {
                    compileWheres(query)
                        .bind(queries: &sql, bindings: &bindings)
                }
                else if component == \Query.groups,
                    let groups = part as? [String],
                    !groups.isEmpty {
                    sql.append(compileGroups(query, groups: groups))
                }
                else if component == \Query.havings {
                    compileHavings(query)
                        .bind(queries: &sql, bindings: &bindings)
                }
                else if component == \Query.orders,
                    let orders = part as? [OrderClause],
                    !orders.isEmpty {
                    sql.append(compileOrders(query, orders: orders))
                }
                else if component == \Query.limit, let limit = part as? Int {
                    sql.append(compileLimit(query, limit: limit))
                }
                else if component == \Query.offset, let offset = part as? Int {
                    sql.append(compileOffset(query, offset: offset))
                }
            }
        }
        return SQL(sql.joined(separator: " "), bindings: bindings)
    }

    private func compileColumns(_ query: Query, columns: [Raw]) -> SQL {
        let select = query._distinct ? "select distinct" : "select"
        let (sql, bindings) = QueryHelpers.groupSQL(values: columns)
        return SQL("\(select) \(sql.joined(separator: ", "))", bindings: bindings)
    }

    private func compileFrom(_ query: Query, table: String) -> String {
        return "from \(table)"
    }

    func compileJoins(_ query: Query, joins: [JoinClause]) -> SQL {
        var bindings: [DatabaseValue] = []
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

    private func compileWheres(_ query: Query) -> SQL {

        // If we actually have some where clauses, we will strip off the first boolean
        // operator, which is added by the query builders for convenience so we can
        // avoid checking for the first clauses in each of the compilers methods.

        // Need to handle nested stuff somehow
        
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.wheres)
        if (sql.count > 0) {
            let conjunction = query is JoinClause ? "on" : "where"
            let clauses = QueryHelpers.removeLeadingBoolean(
                sql.joined(separator: " ")
            )
            return SQL("\(conjunction) \(clauses)", bindings: bindings)
        }
        return SQL()
    }


    func compileGroups(_ query: Query, groups: [String]) -> String {
        return "group by \(groups.joined(separator: ", "))"
    }

    func compileHavings(_ query: Query) -> SQL {
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.havings)
        if (sql.count > 0) {
            let clauses = QueryHelpers.removeLeadingBoolean(
                sql.joined(separator: " ")
            )
            return SQL("having \(clauses)", bindings: bindings)
        }
        return SQL()
    }

    func compileOrders(_ query: Query, orders: [OrderClause]) -> String {
        let ordersSQL = orders.map { $0.toSQL().query }.joined(separator: ", ")
        return "order by \(ordersSQL)"
    }

    func compileLimit(_ query: Query, limit: Int) -> String {
        return "limit \(limit)"
    }

    func compileOffset(_ query: Query, offset: Int) -> String {
        return "offset \(offset)"
    }

    func compileInsert(_ query: Query, values: [KeyValuePairs<String, Parameter>]) throws -> SQL {
        
        guard let table = query.from else { throw GrammarError.missingTable }

        if values.isEmpty {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].map { $0.key }.joined(separator: ", ")
        var parameters: [DatabaseValue] = []
        var placeholders: [String] = []

        for value in values {
            parameters.append(contentsOf: value.map { $0.value.value })
            placeholders.append("(\(parameterize(value.map { $0.value })))")
        }
        return SQL(
            "insert into \(table) (\(columns)) values \(placeholders.joined(separator: ", "))",
            bindings: parameters
        )
    }

    func compileUpdate(_ query: Query, values: [String: Parameter]) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        var bindings: [DatabaseValue] = []
        let columnSQL = compileUpdateColumns(query, values: values)

        var base = "update \(table)"
        if let clauses = query.joins {
            let joinSQL = compileJoins(query, joins: clauses).bind(&bindings)
            base += " \(joinSQL)"
        }
        bindings += columnSQL.bindings
        let whereSQL = compileWheres(query).bind(&bindings)
        return SQL(
            "\(base) set \(columnSQL.query) \(whereSQL.query)",
            bindings: bindings
        )
    }

    func compileUpdateColumns(_ query: Query, values: [String: Parameter]) -> SQL {
        var bindings: [DatabaseValue] = []
        var parts: [String] = []
        for value in values {
            if let expression = value.value as? Expression {
                parts.append("\(value.key) = \(expression.description)")
            }
            else {
                bindings.append(value.value.value)
                parts.append("\(value.key) = ?")
            }
        }

        return SQL(parts.joined(separator: ", "), bindings: bindings)
    }

    func compileDelete(_ query: Query) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        let whereSQL = compileWheres(query)
        return SQL("delete from \(table) \(whereSQL.query)", bindings: whereSQL.bindings)
    }



    private func parameterize(_ values: [Parameter]) -> String {
        return values.map { parameter($0) }.joined(separator: ", ")
    }

    private func parameter(_ value: Parameter) -> String {
        if let value = value as? Expression {
            return value.description
        }
        return "?"
    }

    private func trim(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
