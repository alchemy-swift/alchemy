# Database: Migrations

- [Creating a migration](#creating-a-migration)
- [Implementing Migrations](#implementing-migrations)
- [Schema functions](#schema-functions)
- [Creating a table](#creating-a-table)
  * [Adding Columns](#adding-columns)
  * [Adding Indexes](#adding-indexes)
- [Altering a Table](#altering-a-table)
- [Other schema functions](#other-schema-functions)
- [Running a Migration](#running-a-migration)
  * [Via Command](#via-command)
    + [Applying](#applying)
    + [Rolling Back](#rolling-back)
  * [Via Code](#via-code)
    + [Applying](#applying-1)
    + [Rolling Back](#rolling-back-1)

Migrations are a key part of working with an SQL database. Each migration defines changes to the schema of your database that can be either applied or rolled back. You'll typically create new migrations each time you want to make a change to your database, so that you can keep track of all the changes you've made over time.

## Creating a migration
You can create a new migration using the CLI.

```bash
alchemy make:migration MyMigration
```

This will create a new migration file in `Sources/App/Migrations`.

## Implementing Migrations

A migration conforms to the `Migration` protocol and is implemented by filling out the `up` and `down` functions. `up` is run when a migration is applied to a database. `down` is run when a migration is rolled back. 

`up` and `down` are passed a `Schema` object representing the schema of the database to which this migration will be applied. The database schema is modified via functions on `Schema`.

For example, this migration renames the `user_todos` table to `todos`. Notice the `down` function does the reverse. You don't _have_ to fill out the down function of a migration, but it may be useful for rolling back the operation later.

```swift
struct RenameTodos: Migration {
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
    table.uuid("mom").references("id", on: "users")
}
```

### Adding Columns

You may add a column onto a table builder with functions like `.string()` or `.int()`. These define a named column of the given type and return a column builder for adding modifiers to the column.

Supported builder functions for adding columns are

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
schema.raw("drop schema public cascade")
```

## Running a Migration

To begin, you need to ensure that your migrations are registered on `Database.default`. You can should do this in your `Application.boot` function.

```swift
// Make sure to register a database with `Database.config(default: )` first!
Database.default.migrations = [
    CreateUsers(),
    CreateTodos(),
    RenameTodos()
]
```

### Via Command

#### Applying

You can then apply all outstanding migrations in a single batch by passing the `migrate` argument to your app. This will cause the app to migrate `Database.default` instead of serving.

```bash
# Applies all outstanding migrations
swift run Server migrate 
```

#### Rolling Back

You can pass the `--rollback` flag to instead rollback the latest batch of migrations.

```bash
# Rolls back the most recent batch of migrations
swift run Server migrate --rollback
```

#### When Serving

If you'd prefer to avoid running a separate migration command, you may pass the `--migrate` flag when running your server to automatically run outstanding migrations before serving.

```swift
swift run Server --migrate
```

**Note**: Alchemy keeps track of run migrations and the current batch in your database in the `migrations` table. You can delete this table to clear all records of migrations.

### Via Code

#### Applying

You may also migrate your database in code. The future will complete when the migration is finished.

```swift
database.migrate()
```

#### Rolling Back

Rolling back the latest migration batch is also possible in code.

```swift
database.rollbackMigrations()
```

_Next page: [Redis](5d_Redis.md)_

_[Table of Contents](/Docs#docs)_
