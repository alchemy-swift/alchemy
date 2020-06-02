import Foundation

public class Grammar {

    enum GrammarError: Error {
        case missingTable
    }

    func compileSelect(query: Query) throws -> SQL {
        let parts: [SQL?] = [
            compileColumns(query, columns: query.columns),
            try compileFrom(query, table: query.from),
            compileJoins(query, joins: query.joins),
            compileWheres(query),
            compileGroups(query, groups: query.groups),
            compileHavings(query),
            compileOrders(query, orders: query.orders),
            compileLimit(query, limit: query.limit),
            compileOffset(query, offset: query.offset)
        ]

        let (sql, bindings) = QueryHelpers.groupSQL(values: parts)
        return SQL(sql.joined(separator: " "), bindings: bindings)
    }

    private func compileColumns(_ query: Query, columns: [Raw]) -> SQL {
        let select = query._distinct ? "select distinct" : "select"
        let (sql, bindings) = QueryHelpers.groupSQL(values: columns)
        return SQL("\(select) \(sql.joined(separator: ", "))", bindings: bindings)
    }

    private func compileFrom(_ query: Query, table: String?) throws -> SQL {
        guard let table = table else { throw GrammarError.missingTable }
        return SQL("from \(table)")
    }

    func compileJoins(_ query: Query, joins: [JoinClause]?) -> SQL? {
        guard let joins = joins else { return nil }
        var bindings: [DatabaseValue] = []
        let query = joins.compactMap { join in
            guard let whereSQL = compileWheres(join) else {
                return nil
            }
            bindings += whereSQL.bindings
            if let nestedJoins = join.joins,
                let nestedSQL = compileJoins(query, joins: nestedJoins) {
                bindings += nestedSQL.bindings
                return trim("\(join.type) join (\(join.table)\(nestedSQL.query)) \(whereSQL.query)")
            }
            return trim("\(join.type) join \(join.table) \(whereSQL.query)")
        }.joined(separator: " ")
        return SQL(query, bindings: bindings)
    }

    private func compileWheres(_ query: Query) -> SQL? {

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
        return nil
    }


    func compileGroups(_ query: Query, groups: [String]) -> SQL? {
        if groups.isEmpty { return nil }
        return SQL("group by \(groups.joined(separator: ", "))")
    }

    func compileHavings(_ query: Query) -> SQL? {
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.havings)
        if (sql.count > 0) {
            let clauses = QueryHelpers.removeLeadingBoolean(
                sql.joined(separator: " ")
            )
            return SQL("having \(clauses)", bindings: bindings)
        }
        return nil
    }

    func compileOrders(_ query: Query, orders: [OrderClause]) -> SQL? {
        if orders.isEmpty { return nil }
        let ordersSQL = orders.map { $0.toSQL().query }.joined(separator: ", ")
        return SQL("order by \(ordersSQL)")
    }

    func compileLimit(_ query: Query, limit: Int?) -> SQL? {
        guard let limit = limit else { return nil }
        return SQL("limit \(limit)")
    }

    func compileOffset(_ query: Query, offset: Int?) -> SQL? {
        guard let offset = offset else { return nil }
        return SQL("offset \(offset)")
    }

    func compileInsert(_ query: Query, values: [OrderedDictionary<String, Parameter>]) throws -> SQL {
        
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
        if let clauses = query.joins,
            let joinSQL = compileJoins(query, joins: clauses) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " set \(columnSQL.query)"

        if let whereSQL = compileWheres(query) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.query)"
        }
        return SQL(base, bindings: bindings)
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
        if let whereSQL = compileWheres(query) {
            return SQL("delete from \(table) \(whereSQL.query)", bindings: whereSQL.bindings)
        }
        else {
            return SQL("delete from \(table)")
        }
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
