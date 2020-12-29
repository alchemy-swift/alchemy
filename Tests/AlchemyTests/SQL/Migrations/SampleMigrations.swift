import Alchemy

private struct DatabaseJSON: Encodable {
    let name = "Josh"
    let age = 27
}

private let kSQLDateFormatter = ISO8601DateFormatter()
private let kFixedUUID = UUID(uuidString: "bd81f2b2-e1c2-4f6d-afb5-651c8ba55ad2")!
private let kFixedDate = Date(timeIntervalSince1970: 0)

protocol TestMigration: Migration {
    var expectedUpStatementsPostgreSQL: [SQL] { get }
    var expectedUpStatementsMySQL: [SQL] { get }
}

struct Migration1: TestMigration {
    func up(schema: Schema) {
        schema.create(table: "users") {
            $0.uuid("id").primary().default(expression: "uuid_generate_v4()")
            $0.double("bmi").default(val: 15.0)
            $0.string("email").notNull().unique()
            $0.int("age").default(val: 21)
            $0.increments("counter")
            $0.bool("is_pro").default(val: false)
            $0.date("created_at")
            $0.date("date_default").default(val: kFixedDate)
            $0.uuid("uuid_default").default(val: kFixedUUID)
            $0.json("some_json").default(json: DatabaseJSON())
            $0.uuid("parent_id").references("id", on: "users")
        }
        schema.rename(table: "foo", to: "bar")
        schema.drop(table: "baz")
    }
    
    func down(schema: Schema) {}
    
    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE users (
                    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                    bmi float8 DEFAULT 15.0,
                    email text NOT NULL UNIQUE,
                    age int DEFAULT 21,
                    counter SERIAL,
                    is_pro bool DEFAULT false,
                    created_at timestamptz,
                    date_default timestamptz DEFAULT \(kSQLDateFormatter.string(from: kFixedDate)),
                    uuid_default uuid DEFAULT '\(kFixedUUID.uuidString)',
                    some_json json DEFAULT '{"name":"Josh","age":27}'::jsonb,
                    parent_id uuid REFERENCES users(id)
                )
                """),
            SQL("ALTER TABLE foo RENAME TO bar"),
            SQL("DROP TABLE baz"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        []
    }
}

struct Migration2: TestMigration {
    func up(schema: Schema) {
        schema.create(table: "some_table") {
            $0.string("email")
            $0.addIndex(columns: ["email"], isUnique: true)
        }
        schema.alter(table: "users") {
            $0.drop(index: "some_index_name_idx")
            $0.addIndex(columns: ["foo", "bar"], isUnique: false)
            $0.addIndex(columns: ["baz"], isUnique: true)
        }
    }
    
    func down(schema: Schema) {}
    
    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE some_table (
                    email text
                )
                """),
            SQL("CREATE UNIQUE INDEX some_table_email_key ON some_table"),
            SQL("DROP INDEX some_index_name_idx"),
            SQL("CREATE INDEX users_foo_bar_idx ON users"),
            SQL("CREATE UNIQUE INDEX users_baz_key ON users"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        []
    }
}

struct Migration3: TestMigration {
    func up(schema: Schema) {
        schema.alter(table: "users") {
            $0.drop(column: "email")
            $0.rename(column: "Name", to: "name")
            $0.string("some_string").default(val: "hello")
            $0.drop(column: "other")
        }
        schema.raw(sql: "some raw sql")
    }
    
    func down(schema: Schema) {}
    
    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                ALTER TABLE users
                ADD COLUMN some_string text DEFAULT 'hello',
                DROP COLUMN email,
                DROP COLUMN other
                """),
            SQL("ALTER TABLE users RENAME COLUMN Name TO name"),
            SQL("some raw sql"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        []
    }
}
