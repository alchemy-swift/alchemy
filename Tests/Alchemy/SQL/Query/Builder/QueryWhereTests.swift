//@testable
//import Alchemy
//import AlchemyTest
//
//final class QueryWhereTests: TestCase<TestApp> {
//    override func setUp() {
//        super.setUp()
//        Database.stub()
//    }
//    
//    func testWhere() {
//        let query = DB.table("foo")
//            .where("foo" == 1)
//            .orWhere("bar" == 2)
//        XCTAssertEqual(query.wheres, [_andWhere(), _orWhere(key: "bar", value: 2)])
//    }
//    
//    func testNestedWhere() {
//        let query = DB.table("foo")
//            .where { $0.where("foo" == 1).orWhere("bar" == 2) }
//            .orWhere { $0.where("baz" == 3).orWhere("fiz" == 4) }
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.nested(wheres: [
//                _andWhere(),
//                _orWhere(key: "bar", value: 2)
//            ])),
//            _orWhere(.nested(wheres: [
//                _andWhere(key: "baz", value: 3),
//                _orWhere(key: "fiz", value: 4)
//            ]))
//        ])
//    }
//    
//    func testWhereIn() {
//        let query = DB.table("foo")
//            .where("foo", in: [1])
//            .orWhere("bar", in: [2])
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.in(key: "foo", values: [.int(1)], type: .in)),
//            _orWhere(.in(key: "bar", values: [.int(2)], type: .in)),
//        ])
//    }
//    
//    func testWhereNotIn() {
//        let query = DB.table("foo")
//            .whereNot("foo", in: [1])
//            .orWhereNot("bar", in: [2])
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.in(key: "foo", values: [.int(1)], type: .notIn)),
//            _orWhere(.in(key: "bar", values: [.int(2)], type: .notIn)),
//        ])
//    }
//    
//    func testWhereRaw() {
//        let query = DB.table("foo")
//            .whereRaw("foo", bindings: [1])
//            .orWhereRaw("bar", bindings: [2])
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.raw(SQL("foo", bindings: [.int(1)]))),
//            _orWhere(.raw(SQL("bar", bindings: [.int(2)]))),
//        ])
//    }
//    
//    func testWhereColumn() {
//        let query = DB.table("foo")
//            .whereColumn(first: "foo", op: .equals, second: "bar")
//            .orWhereColumn(first: "baz", op: .like, second: "fiz")
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.column(first: "foo", op: .equals, second: "bar")),
//            _orWhere(.column(first: "baz", op: .like, second: "fiz")),
//        ])
//    }
//    
//    func testWhereNull() {
//        let query = DB.table("foo")
//            .whereNull("foo")
//            .orWhereNull("bar")
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.raw(SQL("foo IS NULL"))),
//            _orWhere(.raw(SQL("bar IS NULL"))),
//        ])
//    }
//    
//    func testWhereNotNull() {
//        let query = DB.table("foo")
//            .whereNotNull("foo")
//            .orWhereNotNull("bar")
//        XCTAssertEqual(query.wheres, [
//            _andWhere(.raw(SQL("foo IS NOT NULL"))),
//            _orWhere(.raw(SQL("bar IS NOT NULL"))),
//        ])
//    }
//    
//    func testCustomOperators() {
//        XCTAssertEqual("foo" == 1, _andWhere(op: .equals))
//        XCTAssertEqual("foo" != 1, _andWhere(op: .notEqualTo))
//        XCTAssertEqual("foo" < 1, _andWhere(op: .lessThan))
//        XCTAssertEqual("foo" > 1, _andWhere(op: .greaterThan))
//        XCTAssertEqual("foo" <= 1, _andWhere(op: .lessThanOrEqualTo))
//        XCTAssertEqual("foo" >= 1, _andWhere(op: .greaterThanOrEqualTo))
//        XCTAssertEqual("foo" ~= 1, _andWhere(op: .like))
//    }
//    
//    private func _andWhere(key: String = "foo", op: SQLQuery.Operator = .equals, value: SQLValueConvertible = 1) -> SQLWhere {
//        _andWhere(.value(key: key, op: op, value: value.sqlValue))
//    }
//    
//    private func _orWhere(key: String = "foo", op: SQLQuery.Operator = .equals, value: SQLValueConvertible = 1) -> SQLWhere {
//        _orWhere(.value(key: key, op: op, value: value.sqlValue))
//    }
//    
//    private func _andWhere(_ type: SQLWhereType) -> SQLWhere {
//        SQLWhere(type: type, boolean: .and)
//    }
//    
//    private func _orWhere(_ type: SQLWhereType) -> SQLWhere {
//        SQLWhere(type: type, boolean: .or)
//    }
//}
