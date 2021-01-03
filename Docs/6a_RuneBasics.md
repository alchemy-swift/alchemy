# Rune: Basics

Alchemy includes Rune, an object-relational mapper (ORM) to make it simple to interact with your database. With Rune, each database table has a corresponding `Model` type that is used to interact with that table. Use this Model type for querying, inserting, updating or deleting from the table.

## Creating a Model

To get started, implement the Model protocol. Models are are build on Swift's `Codable` APIs, so each property of your Model will correspond to a table column with the same name.

By default, your model will correspond to a table with the name of your model type. For custom table names, you can override the static `tableName: String` property.

```swift
struct User: Model {
    static let tableName = "users"

    var id: Int?
    let firstName: String
    let lastName: String
    let age: Int
}
```

_Next page: [Rune: Relationships](6b_RuneRelationships.md)_

_[Table of Contents](/Docs)_