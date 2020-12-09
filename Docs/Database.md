# Database

## Introduction

Alchemy makes interacting with SQL databases a breeze using either raw SQL, an extensive [Query Builder](QueryBuilder.md), or the [Rune ORM](Rune.md).

## Connecting to a Database

Out of the box, Alchemy supports connecting to Postgres & MySQL databases.

Configure the database & run a query on 
```swift
let postgresConfig = PostgresConfig(
        // Unix sockets are also available: `.unixSocket(path: "/foo/bar/baz")`
        socket: .ipAddress(host: "127.0.0.1", port: 5432),
        database: "my_database",
        username: "leeroy",
        password: "P@ssw0rd"
    )
}

let database: Database = PostgresDatabase(config: postgresConfig)

// Database queries are all asynchronous and thus use `EventLoopFuture`s in 
// their API.
database.runRawQuery("select * from users;")
    .whenSuccess { rows in
        print("Got \(rows.count) results!")
    }
```

## Querying data

You can query with SQL strings using the `runQuery` or `runRawQuery` methods. `runQuery` supports bindings, `runRawQuery` does not.

```swift
let email = "josh@five.money"

// Executing a raw query
database.runRawQuery("select * from users where email='\(email)';")

// Using bindings to help avoid SQL injection
database.runQuery("select * from users where email=?;", values: [.string(email)])
```

Every query returns an array of `DatabaseRow`s that you can use to parse out data.

```swift
dataBase.runQuery("select * from users;")
    .map { rows in
        
    }
```

You can attempt to parse out 