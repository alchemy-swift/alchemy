# Database: Migrations

Migrations are a key part of development experience. They apply or rollback changes to the schema of your database and are typically used when adding new models or removing old models.

## Creating a migration
You can create a new migration using the CLI.

```bash
alchemy new migration
```

This will create a new migration file in the `Migrations/` directory named with the current timestamp.

A migration conforms to the `Migration` protocol and is implemented by filling in the `up` and `down` functions. `up` is run when a migration is run on a database. `down` is run when a migration is rolled back. 

Each query in the migration is run on the schema object passed to the up and down functions, representing the Database's schema.

For example, this migration renames the `user_todos` table to `todos`. Notice the `down` function does the reverse; while it could be left empty, it may be useful for rolling back the operation.

```swift
struct Migration09282020: Migration {
    func up(schema: Schema) {
        schema.rename(table: "user_todos", to: "todos")
    }

    func down(schema: Schema) {
        schema.rename(table: "todos", to: "user_todos")
    }
}
```

## Schema functions

The schema has a variety of useful methods for applying various schema migrations.

## Creating a table

You can create a new table using `Schema.create(table: String, builder: (inout CreateTableBuilder) -> Void)`.

The `CreateTableBuilder` comes packed with a variety of functions for adding columns of various types & modifiers to the new table.

```swift
schema.create(table: "users") { newTable in
    newTable.uuid("id").primary()
    newTable.string("name").nullable(false)
    newTable.string("email").nullable(false).unique()
    newTable.uuid("mom").references("id", on: "")
}
```

For an exhaustive list of `CreateTableBuilder` functions, check out [the docs](#).

## Altering an existing new table

You can alter an existing table with `alter(table: String, builder: (inout AlterTableBuilder) -> Void)`.

`AlterTableBuilder` has the exact same interface as `CreateTableBuilder` with a few extra functions for dropping columns & indexes and renaming columns.

```swift
schema.alter(table: "tokens") {
    $0.rename(column: "createdAt", to: "created_at")
    $0.bool("is_expired").default(val: false)
    $0.drop(column: "expiry_date")
}
```

## Other schema functions

You can also drop tables, rename tables, or execute raw SQL from a migration.

```swift
schema.drop(table: "old_users")
schema.rename(table: "createdAt", to: "created_at")

// Run as a subsequent, independent SQL command.
schema.raw(table: "SOME SQL")
```


_Next page: [Rune: Basics](6a_RuneBasics.md)_

_[Table of Contents](/Docs)_