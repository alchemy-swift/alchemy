@testable import Alchemy
import XCTest

final class MigrationTests: XCTestCase {
    private struct SomeJSON: Encodable {
        let name = "Josh"
        let age = 27
    }
    
    func testTables() {
        XCTAssertEqual(Schema {
            $0.create(table: "users") { table in
                table.uuid("id").primary().default(expression: "uuid_generate_v4()")
                table.double("bmi").default(val: 15.0)
                table.string("email").notNull().unique()
                table.int("age").default(val: 21)
                table.bool("is_pro")
                table.date("created_at")
                table.json("some_json").default(json: SomeJSON())
                table.uuid("parent_id").references("id", on: "users")
            }
            $0.rename(table: "foo", to: "bar")
            $0.drop(table: "baz")
        }.statements, [
            SQL("""
                CREATE TABLE users (
                    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                    bmi float8 DEFAULT 15.0,
                    email text NOT NULL UNIQUE,
                    age int DEFAULT 21,
                    is_pro bool,
                    created_at timestamptz,
                    some_json json DEFAULT '{"name":"Josh","age":27}'::jsonb,
                    parent_id uuid REFERENCES users(id)
                )
                """),
            SQL("ALTER TABLE foo RENAME TO bar"),
            SQL("DROP TABLE baz")
        ])
    }
    
    func testIndexes() {
        let states = Schema {
            $0.create(table: "some_table") { table in
                table.string("email")
                table.addIndex(columns: ["email"], isUnique: true)
            }
            
            $0.alter(table: "users") { table in
                table.addIndex(columns: ["foo", "bar"], isUnique: false)
                table.addIndex(columns: ["baz"], isUnique: true)
                table.drop(index: "some_index_name_idx")
            }
        }.statements
        
        for s in states {
            print(s.query)
        }
        
        XCTAssertEqual(Schema {
            $0.create(table: "some_table") { table in
                table.string("email")
                table.addIndex(columns: ["email"], isUnique: true)
            }
            $0.alter(table: "users") { table in
                table.drop(index: "some_index_name_idx")
                table.addIndex(columns: ["foo", "bar"], isUnique: false)
                table.addIndex(columns: ["baz"], isUnique: true)
            }
        }.statements, [
            SQL("""
                CREATE TABLE some_table (
                    email text
                )
                """),
            SQL("CREATE UNIQUE INDEX some_table_email_key ON some_table"),
            SQL("DROP INDEX some_index_name_idx"),
            SQL("CREATE INDEX users_foo_bar_idx ON users"),
            SQL("CREATE UNIQUE INDEX users_baz_key ON users"),
        ])
    }
    
    func testAlterTable() {
        XCTAssertEqual(Schema {
            $0.alter(table: "users") { table in
                table.drop(column: "email")
                table.rename(column: "Name", to: "name")
                table.string("some_string").default(val: "hello")
                table.drop(column: "other")
            }
        }.statements, [
            SQL("""
                ALTER TABLE users
                ADD COLUMN some_string text DEFAULT 'hello',
                DROP COLUMN email,
                DROP COLUMN other
                """),
            SQL("ALTER TABLE users RENAME COLUMN Name TO name"),
        ])
    }
}

extension Schema {
    convenience init(setup: (Schema) -> Void) {
        self.init(grammar: Grammar())
        setup(self)
    }
}
