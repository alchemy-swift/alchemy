@testable import Alchemy
import XCTest

final class MigrationTests: XCTestCase {
    private struct SomeJSON: Encodable {
        let name = "Josh"
        let age = 26
    }
    
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
        XCTAssertEqual(Schema {
            $0.create(table: "users") { table in
                table.uuid("id").primary().default(expression: "uuid_generate_v4()")
                table.double("bmi").default(val: 15.0)
                table.string("name")
                table.int("age").default(val: 21)
                table.bool("is_pro")
                table.timestamp("created_at")
                table.json("some_json").default(val: SomeJSON().sql)
            }
        }.statements, [
            SQL("""
                CREATE TABLE users (
                    id uuid PRIMARY KEY DEFAULT uuid_generate_v4()
                    bmi float8 DEFAULT 15.0
                    name text
                    age int DEFAULT 21
                    is_pro bool
                    created_at timestampz
                    some_json json DEFAULT {"name":"Josh","age":26}
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
