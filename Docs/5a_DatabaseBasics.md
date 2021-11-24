# Database: Basics

- [Introduction](#introduction)
- [Connecting to a Database](#connecting-to-a-database)
- [Querying data](#querying-data)
    * [Handling Query Responses](#handling-query-responses)
    * [Transactions](#transactions)

## Introduction

Alchemy makes interacting with SQL databases a breeze. You can use raw SQL, the fully featured [query builder](5b_DatabaseQueryBuilder.md) or the built in ORM, [Rune](6a_RuneBasics.md).

## Connecting to a Database

Out of the box, Alchemy supports connecting to Postgres & MySQL databases. Database is a `Service` and so is configurable with the `config` function.

```swift
Database.config(default: .postgres(
    host: Env.DB_HOST ?? "localhost",
    database: Env.DB ?? "db",
    username: Env.DB_USER ?? "user",
    password: Env.DB_PASSWORD ?? "password"
))

// Database queries are all asynchronous, using `EventLoopFuture`s in 
// their API.
Database.default
    .rawQuery("select * from users;")
    .whenSuccess { rows in
        print("Got \(rows.count) results!")
    }
```

## Querying data

You can query with raw SQL strings using `Database.rawQuery`. It supports bindings to protect against SQL injection.

```swift
let email = "josh@withapollo.com"

// Executing a raw query
database.rawQuery("select * from users where email='\(email)';")

// Using bindings to protect against SQL injection
database.rawQuery("select * from users where email=?;", values: [.string(email)])
```

**Note** regardless of SQL dialect, please use `?` as placeholders for bindings. Concrete `Database`s representing dialects that use other placeholders, such as `PostgresDatabase`, will replace `?`s with the proper placeholder.

### Handling Query Responses

Every query returns a future with an array of `SQLRow`s that you can use to parse out data. You can access all their columns with `allColumns` or try to get the value of a column with `.get(String) throws -> SQLValue`.

```swift
dataBase.rawQuery("select * from users;")
    .mapEach { (row: SQLRow) in
        print("Got a user with columns: \(row.columns.join(", "))")
        let email = try! row.get("email").string()
        print("The email of this user was: \(email)")
    }
```

Note that `SQLValue` contains functions for casting the value to a specific Swift data type, such as `.string()` above.

```swift
let value: SQLValue = ...

let uuid: UUID = try value.uuid()
let string: String = try value.string()
let int: Int = try value.int()
let bool: Bool = try value.bool()
let double: Double = try value.double()
let json: Data = try value.json()
```

These functions will throw if the value isn't convertible to that type.

### Transactions

Sometimes, you'll want to run multiple database queries as a single atomic operation. For this, you can use the `transaction()` function; a wrapper around SQL transactions. You'll have exclusive access to a database connection for the lifetime of your transaction.

```swift
database.transaction { conn in
    conn.query()
        .where("account" == 1)
        .update(values: ["amount": 100])
        .flatMap { _ in
            conn.query()
                .where("account" == 2)
                .update(values: ["amount": 200])
        }
}
```

_Next page: [Database: Query Builder](5b_DatabaseQueryBuilder.md)_

_[Table of Contents](/Docs#docs)_
