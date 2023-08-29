//@testable import Alchemy
//import XCTest
//
//final class MigrationTests: XCTestCase {
//    private let m1 = Migration1()
//    private let m2 = Migration2()
//    private let m3 = Migration3()
//    
//    func testMigrationNames() {
//        XCTAssertEqual(self.m1.name, "Migration1")
//        XCTAssertEqual(self.m2.name, "Migration2")
//        XCTAssertEqual(self.m3.name, "Migration3")
//    }
//    
//    func testMigrationsPostgres() {
//        let postgres = PostgresGrammar()
//        
//        XCTAssert(self.m1.downStatements(for: postgres).isEmpty)
//        XCTAssert(self.m2.downStatements(for: postgres).isEmpty)
//        XCTAssert(self.m3.downStatements(for: postgres).isEmpty)
//        
//        XCTAssertEqual(self.m1.upStatements(for: postgres), self.m1.expectedUpStatementsPostgreSQL)
//        XCTAssertEqual(self.m2.upStatements(for: postgres), self.m2.expectedUpStatementsPostgreSQL)
//        XCTAssertEqual(self.m3.upStatements(for: postgres), self.m3.expectedUpStatementsPostgreSQL)
//    }
//    
//    func testMigrationsMySQL() {
//        let mysql = MySQLGrammar()
//        
//        XCTAssert(self.m1.downStatements(for: mysql).isEmpty)
//        XCTAssert(self.m2.downStatements(for: mysql).isEmpty)
//        XCTAssert(self.m3.downStatements(for: mysql).isEmpty)
//        
//        XCTAssertEqual(self.m1.upStatements(for: mysql), self.m1.expectedUpStatementsMySQL)
//        XCTAssertEqual(self.m2.upStatements(for: mysql), self.m2.expectedUpStatementsMySQL)
//        XCTAssertEqual(self.m3.upStatements(for: mysql), self.m3.expectedUpStatementsMySQL)
//    }
//}
