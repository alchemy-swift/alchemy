import Foundation

protocol WhereClause: Sequelizable {}

public enum WhereBoolean: String {
    case and
    case or
}

public struct WhereValue: WhereClause {
    let key: String
    let op: Operator
    let value: DatabaseValue
    var boolean: WhereBoolean = .and
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        if self.value.isNil {
            if self.op == .notEqualTo {
                return SQL("\(boolean) \(key) IS NOT NULL")
            } else if self.op == .equals {
                return SQL("\(boolean) \(key) IS NULL")
            } else {
                fatalError("Can't use any where operators other than .notEqualTo or .equals if the value is NULL.")
            }
        } else {
            return SQL("\(boolean) \(key) \(op) ?", binding: value)
        }
    }
}

public struct WhereColumn: WhereClause {
    let first: String
    let op: Operator
    let second: Expression
    var boolean: WhereBoolean = .and
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        return SQL("\(boolean) \(first) \(op) \(second.description)")
    }
}

public typealias WhereNestedClosure = (Query) -> Query
public struct WhereNested: WhereClause {
    let database: Database
    let closure: WhereNestedClosure
    var boolean: WhereBoolean = .and
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        let query = self.closure(Query(database: self.database))
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.wheres)
        let clauses = QueryHelpers.removeLeadingBoolean(
            sql.joined(separator: " ")
        )
        return SQL("\(boolean) (\(clauses))", bindings: bindings)
    }
}

public struct WhereIn: WhereClause {
    public enum InType: String {
        case `in`
        case notIn
    }

    let key: String
    let values: [DatabaseValue]
    let type: InType
    var boolean: WhereBoolean = .and
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
        return SQL("\(boolean) \(key) \(type)(\(placeholders))", bindings: values)
    }
}

public struct WhereRaw: WhereClause {
    let query: String
    var values: [DatabaseValue] = []
    var boolean: WhereBoolean = .and
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        return SQL("\(boolean) \(self.query)", bindings: values)
    }
}
