# Database: Migrations

Migrations are a key part of working with an SQL database. Each migration defines changes to the schema of your database that can be either applied or rolled back. You'll typically create new migrations each time you want to make a change to your database, so that you can keep track of all the changes you've made over time.

## Creating a migration
You can create a new migration using the CLI.

```bash
alchemy new migration MyMigration
```

This will create a new migration file in the `Sources/Migrations/` with the current timestamp (`yyyyMMddHHmmss`) and provided name.

**Note**: Generated migration types are prefaced with an underscore since Swift doesn't allow type names to begin with a number.

**Note**: if the `Sources/Migrations` directory doesn't exist, this command will create the file in `Sources/`. If _that_ doesn't exist, it will create the file in the current directory (aka `.`).

## Implementing Migrations

A migration conforms to the `Migration` protocol and is implemented by filling out the `up` and `down` functions. `up` is run when a migration is applied to a database. `down` is run when a migration is rolled back. 

`up` and `down` are passed a `Schema` object representing the schema of the database to which this migration will be applied. The database schema is modified via functions on `Schema`.

For example, this migration renames the `user_todos` table to `todos`. Notice the `down` function does the reverse. You don't _have_ to fill out the down function of a migration, but it may be useful for rolling back the operation later.

```swift
struct _20201231142209RenameTodos: Migration {
    func up(schema: Schema) {
        schema.rename(table: "user_todos", to: "todos")
    }

    func down(schema: Schema) {
        schema.rename(table: "todos", to: "user_todos")
    }
}
```

## Schema functions

`Schema` has a variety of useful builder methods for doing various database migrations.

## Creating a table

You can create a new table using `Schema.create(table: String, builder: (inout CreateTableBuilder) -> Void)`.

The `CreateTableBuilder` comes packed with a variety of functions for adding columns of various types & modifiers to the new table.

```swift
schema.create(table: "users") { table in
    table.uuid("id").primary()
    table.string("name").notNull()
    table.string("email").notNull().unique()
    table.uuid("mom").references("id", on: "")
}
```

### Adding Columns

You may add a column onto a table builder with functions like `.string()` or `.int()`. These define a named column of the given type and return a column builder for adding modifiers to the column.

Supported builder functions for adding columns are are

| Table Builder Functions | Column Builder Functions |
|-|-|
| `.uuid(_ column: String)` | `.default(expression: String)` |
| `.int(_ column: String)` | `.default(val: String)` |
| `.string(_ column: String)` | `.notNull()` |
| `.increments(_ column: String)` | `.unique()` |
| `.double(_ column: String)` | `.primary()` |
| `.bool(_ column: String)` | `.references(_ column: String, on table: String)` |
| `.date(_ column: String)` |
| `.json(_ column: String)` |

### Adding Indexes

Indexes can be added via `.addIndex`. They can be on a single column or multiple columns and can be defined as unique or not.

```swift
schema.create(table: "users") { table in
    ...
    table.addIndex(columns: ["email"], unique: true)
}
```

Indexes are named by concatinating table name + columns + "key" if unique or "idx" if not, all joined with underscores. For example, the index defined above would be named `users_email_key`.

## Altering a Table

You can alter an existing table with `alter(table: String, builder: (inout AlterTableBuilder) -> Void)`.

`AlterTableBuilder` has the exact same interface as `CreateTableBuilder` with a few extra functions for dropping columns, dropping indexes, and renaming columns.

```swift
schema.alter(table: "users") {
    $0.bool("is_expired").default(val: false)
    $0.drop(column: "name")
    $0.drop(index: "users_email_key")
    $0.rename(column: "createdAt", to: "created_at")
}
```

## Other schema functions

You can also drop tables, rename tables, or execute arbitrary SQL strings from a migration.

```swift
schema.drop(table: "old_users")
schema.rename(table: "createdAt", to: "created_at")
schema.raw(table: "drop schema public cascade")
```

## Running a Migration

To begin, you need to ensure that your migrations are registered on `Global.database`. You can should do this in your `Application.setup` function.

```swift
// Make sure to register a database with 
// Container.register(Database.self) { ... } first!
Global.database.migrations = [
    _20201220142243CreateUsers(),
    _20201222181209CreateTodos(),
    _20201225094501RenameTodos(),
]
```

### Via Command

#### Applying

You can then apply all outstanding migration in a single batch by passing the `migrate` argument to your app. This will cause the app to migrate `Global.database` instead of serving.

```bash
# Applies all outstanding migrations
./MyServer migrate 
```

#### Rolling Back

You can pass the `--rollback` flag to instead rollback the latest bactch of migrations.

```bash
# Rolls back the most recent batch of migrations
./MyServer migrate --rollback
```

**Note**: Alchemy keeps track of run migrations and the current batch in a `_alchemy_migrations` table of your database. You can delete this table to clear all records of migrations.

### Via Code

#### Applying

You may also migrate your database in code. The future will complete when the migration is finished.

```swift
let future = database.migrate()
```

#### Rolling Back

Rolling back the latest migration batch is also possible in code.

```swift
let future = database.rollbackMigrations()
```

_Next page: [Rune: Basics](6a_RuneBasics.md)_

_[Table of Contents](/Docs)_