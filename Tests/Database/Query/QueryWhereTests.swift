@testable
import Alchemy
import AlchemyTest

final class QueryWhereTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        DB.stub()
    }
    
    func testWhere() {
        let query = DB.table("foo")
            .where("foo" == 1)
            .orWhere("bar" == 2)
        XCTAssertEqual(query.wheres, [_andWhere(clause()), _orWhere(clause(column: "bar", value: 2))])
    }
    
    func testNestedWhere() {
        let query = DB.table("foo")
            .where { $0.where("foo" == 1).orWhere("bar" == 2) }
            .orWhere { $0.where("baz" == 3).orWhere("fiz" == 4) }
        XCTAssertEqual(query.wheres, [
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
    
    func testWhereIn() {
        let query = DB.table("foo")
            .where("foo", in: [1])
            .orWhere("bar", in: [2])
        XCTAssertEqual(query.wheres, [
            _andWhere(.in(column: "foo", values: [.value(.int(1))])),
            _orWhere(.in(column: "bar", values: [.value(.int(2))])),
        ])
    }
    
    func testWhereNotIn() {
        let query = DB.table("foo")
            .whereNot("foo", in: [1])
            .orWhereNot("bar", in: [2])
        XCTAssertEqual(query.wheres, [
            _andWhere(.notIn(column: "foo", values: [.value(.int(1))])),
            _orWhere(.notIn(column: "bar", values: [.value(.int(2))])),
        ])
    }
    
    func testWhereRaw() {
        let query = DB.table("foo")
            .whereRaw("foo", parameters: [.int(1)])
            .orWhereRaw("bar", parameters: [.int(2)])
        XCTAssertEqual(query.wheres, [
            _andWhere(.raw(SQL("foo", parameters: [.int(1)]))),
            _orWhere(.raw(SQL("bar", parameters: [.int(2)]))),
        ])
    }
    
    func testWhereColumn() {
        let query = DB.table("foo")
            .whereColumn("foo", .equals, "bar")
            .orWhereColumn("baz", .like, "fiz")
        XCTAssertEqual(query.wheres, [
            _andWhere(.column(column: "foo", op: .equals, otherColumn: "bar")),
            _orWhere(.column(column: "baz", op: .like, otherColumn: "fiz")),
        ])
    }
    
    func testWhereNull() {
        let query = DB.table("foo")
            .whereNull("foo")
            .orWhereNull("bar")
        XCTAssertEqual(query.wheres, [
            _andWhere(.raw(SQL("foo IS NULL"))),
            _orWhere(.raw(SQL("bar IS NULL"))),
        ])
    }
    
    func testWhereNotNull() {
        let query = DB.table("foo")
            .whereNotNull("foo")
            .orWhereNotNull("bar")
        XCTAssertEqual(query.wheres, [
            _andWhere(.raw(SQL("foo IS NOT NULL"))),
            _orWhere(.raw(SQL("bar IS NOT NULL"))),
        ])
    }
    
    func testCustomOperators() {
        XCTAssertEqual("foo" == 1, clause(op: .equals))
        XCTAssertEqual("foo" != 1, clause(op: .notEqualTo))
        XCTAssertEqual("foo" < 1, clause(op: .lessThan))
        XCTAssertEqual("foo" > 1, clause(op: .greaterThan))
        XCTAssertEqual("foo" <= 1, clause(op: .lessThanOrEqualTo))
        XCTAssertEqual("foo" >= 1, clause(op: .greaterThanOrEqualTo))
        XCTAssertEqual("foo" ~= 1, clause(op: .like))
    }

    func testOperatorDescriptions() {
        XCTAssertEqual(SQLWhere.Operator.equals.description, "=")
        XCTAssertEqual(SQLWhere.Operator.lessThan.description, "<")
        XCTAssertEqual(SQLWhere.Operator.greaterThan.description, ">")
        XCTAssertEqual(SQLWhere.Operator.lessThanOrEqualTo.description, "<=")
        XCTAssertEqual(SQLWhere.Operator.greaterThanOrEqualTo.description, ">=")
        XCTAssertEqual(SQLWhere.Operator.notEqualTo.description, "!=")
        XCTAssertEqual(SQLWhere.Operator.like.description, "LIKE")
        XCTAssertEqual(SQLWhere.Operator.notLike.description, "NOT LIKE")
        XCTAssertEqual(SQLWhere.Operator.raw("foo").description, "foo")
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
