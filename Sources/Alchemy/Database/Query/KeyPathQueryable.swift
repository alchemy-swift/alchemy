/// This is an experimental feature to allow the use of `KeyPath`s when using
/// Models for increased type safety. This can be fleshed out more once
/// Swift 5.9 drops and conformance can be auto generated.
public protocol KeyPathQueryable {
    /// The stored properties on this type, mapped to corresponding columns.
    static var storedProperties: [PartialKeyPath<Self>: String] { get }
}

extension KeyPathQueryable {
    public static func column<M>(for keyPath: KeyPath<Self, M>) -> String? {
        storedProperties[keyPath]
    }
}

/*
 
 For now, `KeyPath` APIs are only available for Dirty & WHERE APIs. Once
 `KeyPathQueryable` is offically supported and Swift 5.9 is released,
 there are some other places if could be used.

 1. GROUP BY
 2. SELECT (esp with variadic generics merged)
 3. ORDER BY

 There's also a lot of opportunities to reduce repeated code & allow for mixed
 usage of typed and untyped APIs.

 */

// MARK: - Dirty

extension Model where Self: KeyPathQueryable {
    public func isDirty<M: ModelProperty & Equatable>(_ keyPath: WritableKeyPath<Self, M>) -> Bool {
        Self.column(for: keyPath).map(isDirty) ?? false
    }

    public func isClean<M: ModelProperty & Equatable>(_ keyPath: WritableKeyPath<Self, M>) -> Bool {
        !isDirty(keyPath)
    }
}

// MARK: - WHERE

public struct TypedWhere<M: Model> {
    let clause: SQLWhere.Clause

    init(_ clause: SQLWhere.Clause) {
        self.clause = clause
    }
}

extension KeyPath where Root: Model & KeyPathQueryable, Value: SQLValueConvertible {
    public static func == (lhs: KeyPath<Root, Value>, rhs: Value) -> TypedWhere<Root> {
        TypedWhere(.value(column: column(for: lhs), op: .equals, value: rhs.sql))
    }

    public static func != (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .notEqualTo, value: rhs.sql)
    }

    public static func < (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .lessThan, value: rhs.sql)
    }

    public static func > (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .greaterThan, value: rhs.sql)
    }

    public static func <= (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .lessThanOrEqualTo, value: rhs.sql)
    }

    public static func >= (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .greaterThanOrEqualTo, value: rhs.sql)
    }

    public static func ~= (lhs: KeyPath<Root, Value>, rhs: Value) -> SQLWhere.Clause {
        .value(column: column(for: lhs), op: .like, value: rhs.sql)
    }

    private static func column(for keyPath: KeyPath<Root, Value>) -> String {
        guard let string = Root.column(for: keyPath) else {
            preconditionFailure("Unable to lookup column with key path \(keyPath).")
        }

        return string
    }
}

extension TypedWhere {
    public static func && (lhs: TypedWhere, rhs: TypedWhere) -> TypedWhere {
        switch (lhs.clause, rhs.clause) {
        case let (.nested(lhsWheres), .nested(rhsWheres)):
            return TypedWhere(.nested(wheres: lhsWheres + rhsWheres))
        case let (.nested(wheres), _):
            return TypedWhere(.nested(wheres: wheres + [.and(rhs.clause)]))
        case let (_, .nested(wheres)):
            return TypedWhere(.nested(wheres: [.and(lhs.clause)] + wheres))
        default:
            return TypedWhere(.nested(wheres: [.and(lhs.clause), .and(rhs.clause)]))
        }
    }

    public static func || (lhs: TypedWhere, rhs: TypedWhere) -> TypedWhere {
        switch (lhs.clause, rhs.clause) {
        case let (.nested(lhsWheres), .nested(rhsWheres)):
            return TypedWhere(.nested(wheres: lhsWheres + rhsWheres))
        case let (.nested(wheres), _):
            return TypedWhere(.nested(wheres: wheres + [.or(rhs.clause)]))
        case let (_, .nested(wheres)):
            guard let first = wheres.first else {
                return lhs
            }

            return TypedWhere(.nested(wheres: [.and(lhs.clause), SQLWhere(boolean: .or, clause: first.clause)] + wheres.dropFirst()))
        default:
            return TypedWhere(.nested(wheres: [.and(lhs.clause), .or(rhs.clause)]))
        }
    }
}

extension Query where Result: Model & KeyPathQueryable {

    // MARK: Value

    public func `where`(_ typedWhere: TypedWhere<Result>) -> Self {
        `where`(typedWhere.clause)
    }

    public func orWhere(_ typedWhere: TypedWhere<Result>) -> Self {
        orWhere(typedWhere.clause)
    }

    public func `where`<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, _ op: SQLWhere.Clause.Operator, _ value: Value) -> Self {
        `where`(.value(column: _column(for: column), op: op, value: value.sql))
    }

    public func orWhere<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, _ op: SQLWhere.Clause.Operator, _ value: Value) -> Self {
        orWhere(.value(column: _column(for: column), op: op, value: value.sql))
    }

    // MARK: IN Array

    public func `where`<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in values: [Value]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("FALSE"))
        }

        return `where`(.in(column: _column(for: column), values: values.map(\.sql)))
    }

    public func orWhere<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in values: [Value]) -> Self {
        guard !values.isEmpty else {
            return orWhere(.raw("FALSE"))
        }

        return orWhere(.in(column: _column(for: column), values: values.map(\.sql)))
    }

    public func whereNot<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in values: [Value]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("TRUE"))
        }

        return `where`(.notIn(column: _column(for: column), values: values.map(\.sql)))
    }

    public func orWhereNot<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in values: [Value]) -> Self {
        guard !values.isEmpty else {
            return orWhere(.raw("TRUE"))
        }

        return orWhere(.notIn(column: _column(for: column), values: values.map(\.sql)))
    }

    // MARK: IN Query

    public func `where`<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in query: Query<SQLRow>) -> Self {
        `where`(.in(column: _column(for: column), values: [query.sql]))
    }

    public func orWhere<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in query: Query<SQLRow>) -> Self {
        orWhere(.in(column: _column(for: column), values: [query.sql]))
    }

    public func whereNot<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in query: Query<SQLRow>) -> Self {
        `where`(.notIn(column: _column(for: column), values: [query.sql]))
    }

    public func orWhereNot<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, in query: Query<SQLRow>) -> Self {
        orWhere(.notIn(column: _column(for: column), values: [query.sql]))
    }

    // MARK: Column

    public func whereColumn<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, _ op: SQLWhere.Clause.Operator, _ otherColumn: KeyPath<Result, Value>) -> Self {
        `where`(.column(column: _column(for: column), op: op, otherColumn: _column(for: otherColumn)))
    }

    public func orWhereColumn<Value: SQLConvertible>(_ column: KeyPath<Result, Value>, _ op: SQLWhere.Clause.Operator, _ otherColumn: KeyPath<Result, Value>) -> Self {
        orWhere(.column(column: _column(for: column), op: op, otherColumn: _column(for: otherColumn)))
    }

    // MARK: NULL

    public func whereNull<Value: SQLConvertible>(_ column: KeyPath<Result, Value>) -> Self {
        `where`(.raw("\(_column(for: column)) IS NULL"))
    }

    public func orWhereNull<Value: SQLConvertible>(_ column: KeyPath<Result, Value>) -> Self {
        orWhere(.raw("\(_column(for: column)) IS NULL"))
    }

    public func whereNotNull<Value: SQLConvertible>(_ column: KeyPath<Result, Value>) -> Self {
        `where`(.raw("\(_column(for: column)) IS NOT NULL"))
    }

    public func orWhereNotNull<Value: SQLConvertible>(_ column: KeyPath<Result, Value>) -> Self {
        orWhere(.raw("\(_column(for: column)) IS NOT NULL"))
    }

    private func _column<Value: SQLConvertible>(for keyPath: KeyPath<Result, Value>) -> String {
        guard let string = Result.column(for: keyPath) else {
            preconditionFailure("Unable to lookup column with key path \(keyPath).")
        }

        return string
    }
}
