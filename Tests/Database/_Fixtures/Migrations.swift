import Alchemy
import Foundation

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
    
    func up(db: Database) async throws {
        try await db.createTable("users", ifNotExists: true) {
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
            $0.json("other_json").default(jsonString: "{}")
            $0.uuid("parent_id").references("id", on: "users", onDelete: .cascade, onUpdate: .cascade)
            $0.addIndex(columns: ["counter"], isUnique: false)
        }
        
        try await db.createTable("foo") {
            $0.increments("id").primary()
        }

        try await db.renameTable("foo", to: "bar")
        try await db.dropTable("bar")
    }
    
    func down(db: Database) async throws {
        //
    }

    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE IF NOT EXISTS users (
                    "id" uuid DEFAULT uuid_generate_v4(),
                    "bmi" float8 DEFAULT 15.0,
                    "email" varchar(255) NOT NULL,
                    "age" int DEFAULT 21,
                    "counter" serial,
                    "is_pro" bool DEFAULT false,
                    "created_at" timestamptz,
                    "date_default" timestamptz DEFAULT '1970-01-01 00:00:00 +0000',
                    "uuid_default" uuid DEFAULT '\(kFixedUUID.uuidString)',
                    "some_json" json DEFAULT '{"age":27,"name":"Josh"}'::jsonb,
                    "other_json" json DEFAULT '{}'::jsonb,
                    "parent_id" uuid,
                    PRIMARY KEY ("id"),
                    UNIQUE ("email"),
                    FOREIGN KEY ("parent_id") REFERENCES users ("id") ON DELETE CASCADE ON UPDATE CASCADE
                )
                """),
            SQL("""
                CREATE INDEX users_counter_idx ON users ("counter")
                """),
            SQL("""
                CREATE TABLE foo (
                    "id" serial,
                    PRIMARY KEY ("id")
                )
                """),
            SQL("ALTER TABLE foo RENAME TO bar"),
            SQL("DROP TABLE bar"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        [
            SQL("""
                CREATE TABLE IF NOT EXISTS users (
                    "id" varchar(36) DEFAULT uuid_generate_v4(),
                    "bmi" double DEFAULT 15.0,
                    "email" varchar(255) NOT NULL,
                    "age" int DEFAULT 21,
                    "counter" serial,
                    "is_pro" boolean DEFAULT false,
                    "created_at" datetime,
                    "date_default" datetime DEFAULT '1970-01-01 00:00:00 +0000',
                    "uuid_default" varchar(36) DEFAULT '\(kFixedUUID.uuidString)',
                    "some_json" json DEFAULT ('{"age":27,"name":"Josh"}'),
                    "other_json" json DEFAULT ('{}'),
                    "parent_id" varchar(36),
                    PRIMARY KEY ("id"),
                    UNIQUE ("email"),
                    FOREIGN KEY ("parent_id") REFERENCES users ("id") ON DELETE CASCADE ON UPDATE CASCADE
                )
                """),
            SQL("""
                CREATE INDEX users_counter_idx ON users ("counter")
                """),
            SQL("""
                CREATE TABLE foo (
                    "id" serial,
                    PRIMARY KEY ("id")
                )
                """),
            SQL("""
                ALTER TABLE foo RENAME TO bar
                """),
            SQL("DROP TABLE bar"),
        ]
    }
}

struct Migration2: TestMigration {
    func up(db: Database) async throws {
        try await db.createTable("some_table") {
            $0.string("email")
            $0.addIndex(columns: ["email"], isUnique: false)
            $0.uuid("user_id").references("id", on: "users").notNull()
        }

        try await db.alterTable("users") {
            $0.drop(index: "users_counter_idx")
            $0.addIndex(columns: ["age", "bmi"], isUnique: false)
        }
    }
    
    func down(db: Database) async throws {
        //
    }

    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                CREATE TABLE some_table (
                    "email" varchar(255),
                    "user_id" uuid NOT NULL,
                    FOREIGN KEY ("user_id") REFERENCES users ("id")
                )
                """),
            SQL("""
                CREATE INDEX some_table_email_idx ON some_table ("email")
                """),
            SQL("DROP INDEX users_counter_idx"),
            SQL("""
                CREATE INDEX users_age_bmi_idx ON users ("age", "bmi")
                """),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        [
            SQL("""
                CREATE TABLE some_table (
                    "email" varchar(255),
                    "user_id" varchar(36) NOT NULL,
                    FOREIGN KEY ("user_id") REFERENCES users ("id")
                )
                """),
            SQL("""
                CREATE INDEX some_table_email_idx ON some_table ("email")
                """),
            SQL("DROP INDEX users_counter_idx ON users"),
            SQL("""
                CREATE INDEX users_age_bmi_idx ON users ("age", "bmi")
                """),
        ]
    }
}

struct Migration3: TestMigration {
    func up(db: Database) async throws {
        try await db.alterTable("users") {
            $0.drop(column: "email")
            $0.rename(column: "bmi", to: "bmi2")
            $0.string("some_string", length: .unlimited).default(val: "hello")
            $0.int("some_int").unique().notNull()
        }

        try await db.raw("some raw sql")
    }
    
    func down(db: Database) async throws {
        //
    }

    var expectedUpStatementsPostgreSQL: [SQL] {
        [
            SQL("""
                ALTER TABLE users
                    ADD COLUMN "some_string" text DEFAULT 'hello',
                    ADD COLUMN "some_int" int NOT NULL,
                    DROP COLUMN "email",
                    ADD UNIQUE ("some_int")
                """),
            SQL("""
                ALTER TABLE users RENAME COLUMN "bmi" TO "bmi2"
                """),
            SQL("some raw sql"),
        ]
    }
    
    var expectedUpStatementsMySQL: [SQL] {
        [
            SQL("""
                ALTER TABLE users
                    ADD COLUMN "some_string" text DEFAULT ('hello'),
                    ADD COLUMN "some_int" int NOT NULL,
                    DROP COLUMN "email",
                    ADD UNIQUE ("some_int")
                """),
            SQL("""
                ALTER TABLE users RENAME COLUMN "bmi" TO "bmi2"
                """),
            SQL("some raw sql"),
        ]
    }
}
