@testable
import Alchemy
import AlchemyTesting

struct QueryWhereTests {
    @Test func `where`() {
        let query = TestQuery("foo")
            .where("foo" == 1)
            .orWhere("bar" == 2)
        #expect(query.wheres == [_andWhere(clause()), _orWhere(clause(column: "bar", value: 2))])
    }

    @Test func nestedWhere() {
        let query = TestQuery("foo")
            .where { $0.where("foo" == 1).orWhere("bar" == 2) }
            .orWhere { $0.where("baz" == 3).orWhere("fiz" == 4) }
        #expect(query.wheres == [
            _andWhere(.nested(wheres: [
                _andWhere(clause()),
                _orWhere(clause(column: "bar", value: 2))
            ])),
            _orWhere(.nested(wheres: [
                _andWhere(clause(column: "baz", value: 3)),
                _orWhere(clause(column: "fiz", value: 4))
            ]))
        ])
    }

    @Test func whereIn() {
        let query = TestQuery("foo")
            .where("foo", in: [1])
            .orWhere("bar", in: [2])
        #expect(query.wheres == [
            _andWhere(.in(column: "foo", values: [.value(.int(1))])),
            _orWhere(.in(column: "bar", values: [.value(.int(2))]))
        ])
    }

    @Test func whereNotIn() {
        let query = TestQuery("foo")
            .whereNot("foo", in: [1])
            .orWhereNot("bar", in: [2])
        #expect(query.wheres == [
            _andWhere(.notIn(column: "foo", values: [.value(.int(1))])),
            _orWhere(.notIn(column: "bar", values: [.value(.int(2))]))
        ])
    }

    @Test func whereRaw() {
        let query = TestQuery("foo")
            .whereRaw("foo", parameters: [.int(1)])
            .orWhereRaw("bar", parameters: [.int(2)])
        #expect(query.wheres == [
            _andWhere(.raw(SQL("foo", parameters: [.int(1)]))),
            _orWhere(.raw(SQL("bar", parameters: [.int(2)])))
        ])
    }

    @Test func whereColumn() {
        let query = Database.stub
            .table("foo")
            .whereColumn("foo", .equals, "bar")
            .orWhereColumn("baz", .like, "fiz")
        #expect(query.wheres == [
            _andWhere(.column(column: "foo", op: .equals, otherColumn: "bar")),
            _orWhere(.column(column: "baz", op: .like, otherColumn: "fiz"))
        ])
    }

    @Test func whereNull() {
        let query = TestQuery("foo")
            .whereNull("foo")
            .orWhereNull("bar")
        #expect(query.wheres == [
            _andWhere(.raw(SQL("foo IS NULL"))),
            _orWhere(.raw(SQL("bar IS NULL")))
        ])
    }

    @Test func whereNotNull() {
        let query = TestQuery("foo")
            .whereNotNull("foo")
            .orWhereNotNull("bar")
        #expect(query.wheres == [
            _andWhere(.raw(SQL("foo IS NOT NULL"))),
            _orWhere(.raw(SQL("bar IS NOT NULL")))
        ])
    }

    @Test func customOperators() {
        #expect(("foo" == 1) == clause(op: .equals))
        #expect(("foo" != 1) == clause(op: .notEqualTo))
        #expect(("foo" < 1) == clause(op: .lessThan))
        #expect(("foo" > 1) == clause(op: .greaterThan))
        #expect(("foo" <= 1) == clause(op: .lessThanOrEqualTo))
        #expect(("foo" >= 1) == clause(op: .greaterThanOrEqualTo))
        #expect(("foo" ~= 1) == clause(op: .like))
    }

    @Test func operatorDescriptions() {
        #expect(SQLWhere.Operator.equals.description == "=")
        #expect(SQLWhere.Operator.lessThan.description == "<")
        #expect(SQLWhere.Operator.greaterThan.description == ">")
        #expect(SQLWhere.Operator.lessThanOrEqualTo.description == "<=")
        #expect(SQLWhere.Operator.greaterThanOrEqualTo.description == ">=")
        #expect(SQLWhere.Operator.notEqualTo.description == "!=")
        #expect(SQLWhere.Operator.like.description == "LIKE")
        #expect(SQLWhere.Operator.notLike.description == "NOT LIKE")
        #expect(SQLWhere.Operator.raw("foo").description == "foo")
    }

    private func clause(column: String = "foo", op: SQLWhere.Operator = .equals, value: SQLConvertible = 1) -> SQLWhere.Clause {
        .value(column: column, op: op, value: value.sql)
    }

    private func _andWhere(_ clause: SQLWhere.Clause) -> SQLWhere {
        SQLWhere(boolean: .and, clause: clause)
    }

    private func _orWhere(_ clause: SQLWhere.Clause) -> SQLWhere {
        SQLWhere(boolean: .or, clause: clause)
    }
}

