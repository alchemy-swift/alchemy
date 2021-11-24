# Rune: Basics

- [Creating a Model](#creating-a-model)
- [Custom Table Names](#custom-table-names)
    * [Custom Key Mappings](#custom-key-mappings)
- [Model Field Types](#model-field-types)
    * [Basic Types](#basic-types)
    * [Advanced Types](#advanced-types)
        + [Enums](#enums)
        + [JSON](#json)
        + [Custom JSON Encoders](#custom-json-encoders)
        + [Custom JSON Decoders](#custom-json-decoders)
- [Decoding from `SQLRow`](#decoding-from-sqlrow)
- [Model Querying](#model-querying)
    * [All Models](#all-models)
    * [First Model](#first-model)
    * [Quick Lookups](#quick-lookups)
- [Model CRUD](#model-crud)
    * [Get All](#get-all)
    * [Save](#save)
    * [Delete](#delete)
    * [Sync](#sync)
    * [Bulk Operations](#bulk-operations)

Alchemy includes Rune, an object-relational mapper (ORM) to make it simple to interact with your database. With Rune, each database table has a corresponding `Model` type that is used to interact with that table. Use this Model type for querying, inserting, updating or deleting from the table.

## Creating a Model

To get started, implement the Model protocol. All it requires is an `id` property. Each property of your `Model` will correspond to a table column with the same name, converted to `snake_case`.

```swift
struct User: Model {
    var id: Int?          // column `id`
    let firstName: String // column `first_name`
    let lastName: String  // column `last_name`
    let age: Int          // column `age`
}
```

**Warning**: `Model` APIs rely heavily on Swift's `Codable`. Please avoid overriding the compiler synthesized `func encode(to: Encoder)` and `init(from: Decoder)` functions. You might be able to get away with it but it could cause issues under the hood. You _can_ however, add custom `CodingKeys` if you like, just be aware of the impact it will have on the `keyMappingStrategy` described below.

## Custom Table Names

By default, your model will correspond to a table with the name of your model type, pluralized. For custom table names, you can override the static `tableName: String` property.

```swift
// Corresponds to table name `users`.
struct User: Model {}

struct Todo: Model {
    static let tableName = "todo_table"
}
```

### Custom Key Mappings

As mentioned, by default all `Model` property names will be converted to `snake_case`, when mapping to corresponding table columns. You may change this behavior via the `keyMapping: DatabaseKeyMapping`. You could set it to `.useDefaultKeys` to use the verbatim `CodingKey`s of the `Model` object, or `.custom((String) -> String)` to provide a custom mapping closure.

```swift
struct User: Model {
    static let keyMapping = .useDefaultKeys

    var id: Int?          // column `id`
    let firstName: String // column `firstName`
    let lastName: String  // column `lastName`
    let age: Int          // column `age`
}
```

## Model Field Types

### Basic Types

Models support most basic Swift types such as `String`, `Bool`, `Int`, `Double`, `UUID`, `Date`. Under the hood, these are mapped to relevant types on the concrete `Database` you are using. 

### Advanced Types

Models also support some more advanced Swift types, such as `enum`s and `JSON`.

#### Enums

`String` or `Int` backed Swift `enum`s are allowed as fields on a `Model`, as long as they conform to `ModelEnum`.

```swift
struct Todo: Model {
    enum Priority: String, ModelEnum {
        case low, medium, high
    }

    var id: Int?
    let name: String
    let isComplete: Bool
    let priority: Priority
}
```

#### JSON

Models require all properties to be `Codable`, so any property that isn't one of the types listed above will be stored as `JSON`.

```swift
struct Todo: Model {
    struct TodoMetadata: Codable {
        var createdAt: Date
        var lastUpdated: Date
        var colorName: String
        var comment: String
    }

    var id: Int?

    let name: String
    let isDone: Bool
    let metadata: TodoMetadata // will be stored as JSON
}
```

#### Custom JSON Encoders

By default, `JSON` properties are encoded using a default `JSONEncoder()` and stored in the table column. You can use a custom `JSONEncoder` by overriding the static `Model.jsonEncoder`.

```swift
struct Todo: Model {
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    ...
}
```

#### Custom JSON Decoders

Likewise, you can provide a custom `JSONDecoder` for decoding data from JSON columns.

```swift
struct Todo: Model {
    static var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    ...
}
```

## Decoding from `SQLRow`

`Model`s may be "decoded" from a `SQLRow` that was the result of a raw query or query builder query. The `Model`'s properties will be mapped to their relevant columns, factoring in any custom `keyMappingStrategy`. This will throw an error if there is an issue while decoding, such as a missing column.

```swift
struct User: Model {
    var id: Int?
    let firstName: String
    let lastName: String
    let age: String
}

database.rawQuery("select * from users")
    .mapEach { try! $0.decode(User.self) }
    .whenSuccess { users in
        for user in users {
            print("Got user named \(user.firstName) \(user.lastName).")
        }
    }
```

**Note**: For the most part, if you are using Rune you won't need to call `SQLRow.decode(_ type:)` because the typed ORM queries described in the next section decode it for you.

## Model Querying

To add some type safety to query builder queries, you can initiate a typed query off of a `Model` with the static `.query` function.

```swift
let users = User.query().allModels()
```

`ModelQuery<M: Model>` is a subclass of the generic `Query`, with a few functions for running and automatically decoding `M` from a query.

### All Models

`.allModels()` returns an EventLoopFuture<[M]> containing all `Model`s that matched the query.

```swift
User.query()
    .where("name", in: ["Josh", "Chris", "Rachel"])
    .allModels() // EventLoopFuture<[User]> of all users named Josh, Chris, or Rachel
```

### First Model

`.firstModel()` returns an `EventLoopFuture<M?>` containing the first `Model` that matched the query, if it exists.

```swift
User.query()
    .where("age" > 30)
    .firstModel() // EventLoopFuture<User?> with the first User over age 30.
```

If you want to throw an error if no item is found, you would `.unwrapFirstModel(or error: Error)`.

```swift
let userEmail = ...
User.query()
    .where("email" == userEmail)
    .unwrapFirstModel(or: HTTPError(.unauthorized))
```

### Quick Lookups

There are also two functions for quickly looking up a `Model`.

`ensureNotExists(where:error:)` does a query to ensure that a `Model` matching the provided where clause doesn't exist. If it does, it throws the provided error.

```swift
func createNewAccount(with email: String) -> EventLoopFuture<Void> {
    User.ensureNotExists(where: "email" == email, else: HTTPError(.conflict))
}
```

`unwrapFirstWhere(_:error:)` is essentially the opposite, finding the first `Model` that matches the provided where clause or throwing an error if one doesn't exist.

```swift
func resetPassword(for email: String) -> EventLoopFuture<Void> {
    User.unwrapFirstWhere("email" == email, or: HTTPError(.notFound))
        .flatMap { user in
            // reset the user's password
        }
}
```

## Model CRUD

There are also convenience functions around creating, fetching, and deleting `Model`s.

### Get All

Fetch all records of a `Model` with the `all()` function.

```swift
User.all()
    .whenSuccess {
        print("There are \($0.count) users.")
    }
```

### Save

Save a `Model` to the database, either inserting it or updating it depending on if it has a nil id.

```swift
// Creates a new user
User(name: "Josh", email: "josh@example.com")
    .save()

User.unwrapFirstWhere("email" == "josh@example.com")
    .flatMap { user in
        user.name = "Joshua"
        // Updates the User's name.
        return user.save()
    }
```

### Delete

Delete an existing `Model` from the database with `delete()`.

```swift
let existingUser: User = ...
existingUser.delete()
    .whenSuccess {
        print("The user is deleted.")
    }
```

### Sync

Fetch an up to date copy of this `Model`.

```swift
let outdatedUser: User = ...
outdatedUser.sync()
    .whenSuccess { upToDateUser in
        print("User's name is: \(upToDateUser.name)")
    }
```

### Bulk Operations

You can also do bulk inserts or deletes on `[Model]`.

```swift
let newUsers: [User] = ...
newUsers.insertAll()
    .whenSuccess { users in
        print("Added \(users.count) new users!")
    }
```

```swift
let usersToDelete: [User] = ...
usersToDelete.deleteAll()
    .whenSuccess {
        print("Added deleted \(usersToDelete.count) users.")
    }
```

_Next page: [Rune: Relationships](6b_RuneRelationships.md)_

_[Table of Contents](/Docs#docs)_
