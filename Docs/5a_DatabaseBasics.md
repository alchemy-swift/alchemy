# Database: Basics

- [Introduction](#introduction)
- [Connecting to a Database](#connecting-to-a-database)
- [Querying data](#querying-data)
  * [Handling Query Responses](#handling-query-responses)

## Introduction

Alchemy makes interacting with SQL databases a breeze using either raw SQL or the fully featured [query builder](5b_DatabaseQueryBuilder.md) and ORM, [Rune](6a_RuneBasics.md).

## Connecting to a Database

Out of the box, Alchemy supports connecting to Postgres & MySQL databases.

Configure the database & run a query on 
```swift
let database = PostgresDatabase(
    config: DatabaseConfig(
        // Unix sockets are also available: `.unixSocket(path: "/foo/bar/baz")`
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "my_database",
        username: "leeroy",
        password: "P@ssw0rd"
    )
)

// Database queries are all asynchronous, using `EventLoopFuture`s in 
// their API.
database.runRawQuery("select * from users;")
    .whenSuccess { rows in
        print("Got \(rows.count) results!")
    }
```

## Querying data

You can query with raw SQL strings using `Database.runRawQuery`. It supports bindings to protect against SQL injection.

```swift
let email = "josh@five.money"

// Executing a raw query
database.runRawQuery("select * from users where email='\(email)';")

// Using bindings to protect against SQL injection
database.runQuery("select * from users where email=?;", values: [.string(email)])
```

**Note** regardless of SQL dialect, please use `?` as placeholders for bindings. Concrete `Database`s representing dialects that use other placeholders, such as `PostgresDatabase`, will replace `?`s with the proper placeholder.

### Handling Query Responses

Every query returns a future with an array of `DatabaseRow`s that you can use to parse out data. You can access all their columns with `allColumns` or try to get the value of a column with `.getField(column: String) throws -> DatabaseField`.

```swift
dataBase.runQuery("select * from users;")
    .mapEach { (row: DatabaseRow) in
        print("Got a user with columns: \(row.allColumns.join(", "))")
        let email = try! row.getField(column: "email").string()
        print("The email of this user was: \(email)")
    }
```

Note that `DatabaseField` is made up of a `column: String` and a `value: DatabaseValue`. It contains functions for casting the value to a specific Swift data type, such as `.string()` above.

```swift
let field: DatabaseField = ...

let uuid: UUID = try field.uuid()
let string: String = try field.string()
let int: Int = try field.int()
let bool: Bool = try field.bool()
let double: Double = try field.double()
let json: Data = try field.json()
```

These functions will throw if the value at the given column isn't convertible to that type.

_Next page: [Database: Query Builder](5b_DatabaseQueryBuilder.md)_

_[Table of Contents](/Docs#docs)_