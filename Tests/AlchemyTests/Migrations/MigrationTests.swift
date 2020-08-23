@testable import Alchemy
import XCTest

final class MigrationTests: XCTestCase {
    func testDropTable() {
        XCTAssertEqual(Schema {
            $0.drop(table: "users")
        }.statements, [
            SQL("DROP TABLE users")
        ])
    }
    
    func testRenameTable() {
        XCTAssertEqual(Schema {
            $0.rename(table: "foo", to: "bar")
        }.statements, [
            SQL("ALTER TABLE foo RENAME TO bar")
        ])
    }
    
    func testCreateTable() {
        let schema = Schema {
            $0.create(table: "users") { table in
                table.uuid("id").primary().default(expression: "uuid_generate_v4()")
                table.string("name")
                table.int("age").default(val: 21)
                table.bool("is_pro")
                table.timestamp("created_at")
            }
        }
        
        for statement in schema.statements {
            print("\(statement.query)")
            print("Bindings: \(statement.bindings.count)")
        }
        
        XCTAssertEqual(schema.statements, [
            SQL("""
                CREATE TABLE users (
                    id uuid PRIMARY KEY DEFAULT uuid_generate_v4()
                    name text
                    age int DEFAULT 21
                    is_pro bool
                    created_at timestampz
                )
                """)
        ])
    }
}

extension Schema {
    convenience init(setup: (Schema) -> Void) {
        self.init()
        setup(self)
    }
}
