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
    private static let orderedEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    
    func up(schema: Schema) {
        schema.create(table: "users", ifNotExists: true) {
            $0.uuid("id").primary().default(expression: "uuid_generate_v4()")
            $0.double("bmi").default(val: 15.0)
            $0.string("email").notNull().unique()
            $0.int("age").default(val: 21)
            $0.increments("counter")
            $0.bool("is_pro").default(val: false)
            $0.date("created_at")
            $0.date("date_default").default(val: kFixedDate)
            $0.uuid("uuid_default").default(val: kFixedUUID)
            $0.json("some_json").default(json: DatabaseJSON(), encoder: Migration1.orderedEncoder)
            $0.uuid("parent_id").references("id", on: "users")
        }
        schema.rename(table: "foo", to: "bar")
        schema.drop(table: "baz")
    }
    
    func down(schema: Schema) {}
    
    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE IF NOT EXISTS users (
                    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                    bmi float8 DEFAULT 15.0,
                    email varchar(255) NOT NULL UNIQUE,
                    age int DEFAULT 21,
                    counter SERIAL,
                    is_pro bool DEFAULT false,
                    created_at timestamptz,
                    date_default timestamptz DEFAULT '1970-01-01T00:00:00',
                    uuid_default uuid DEFAULT '\(kFixedUUID.uuidString)',
                    some_json json DEFAULT '{"age":27,"name":"Josh"}'::jsonb,
                    parent_id uuid REFERENCES users(id)
                )
                """),
            SQL("ALTER TABLE foo RENAME TO bar"),
            SQL("DROP TABLE baz"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        [
            SQL("""
                CREATE TABLE IF NOT EXISTS users (
                    id varchar(36) PRIMARY KEY DEFAULT uuid_generate_v4(),
                    bmi double DEFAULT 15.0,
                    email varchar(255) NOT NULL UNIQUE,
                    age int DEFAULT 21,
                    counter SERIAL,
                    is_pro boolean DEFAULT false,
                    created_at datetime,
                    date_default datetime DEFAULT '1970-01-01T00:00:00',
                    uuid_default varchar(36) DEFAULT '\(kFixedUUID.uuidString)',
                    some_json json DEFAULT ('{"age":27,"name":"Josh"}'),
                    parent_id varchar(36) REFERENCES users(id)
                )
                """),
            SQL("ALTER TABLE foo RENAME TO bar"),
            SQL("DROP TABLE baz"),
        ]
    }
}

struct Migration2: TestMigration {
    func up(schema: Schema) {
        schema.create(table: "some_table") {
            $0.string("email")
            $0.addIndex(columns: ["email"], isUnique: true)
        }
        schema.alter(table: "users") {
            $0.drop(index: "users_email_key")
            $0.addIndex(columns: ["age", "bmi"], isUnique: false)
            $0.addIndex(columns: ["email"], isUnique: true)
        }
    }
    
    func down(schema: Schema) {}
    
    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE some_table (
                    email varchar(255)
                )
                """),
            SQL("CREATE UNIQUE INDEX some_table_email_key ON some_table (email)"),
            SQL("DROP INDEX users_email_key"),
            SQL("CREATE INDEX users_age_bmi_idx ON users (age, bmi)"),
            SQL("CREATE UNIQUE INDEX users_email_key ON users (email)"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        [
            SQL("""
                CREATE TABLE some_table (
                    email varchar(255)
                )
                """),
            SQL("CREATE UNIQUE INDEX some_table_email_key ON some_table (email)"),
            SQL("DROP INDEX users_email_key ON users"),
            SQL("CREATE INDEX users_age_bmi_idx ON users (age, bmi)"),
            SQL("CREATE UNIQUE INDEX users_email_key ON users (email)"),
        ]
    }
}

struct Migration3: TestMigration {
    func up(schema: Schema) {
        schema.alter(table: "users") {
            $0.drop(column: "email")
            $0.rename(column: "Name", to: "name")
            $0.string("some_string", length: .unlimited).default(val: "hello")
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
        [
            SQL("""
                ALTER TABLE users
                ADD COLUMN some_string text DEFAULT ('hello'),
                DROP COLUMN email,
                DROP COLUMN other
                """),
            SQL("ALTER TABLE users RENAME COLUMN Name TO name"),
            SQL("some raw sql"),
        ]
    }
}
