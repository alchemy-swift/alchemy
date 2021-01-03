# Rune: Relationships

Relationships are an important part of an SQL database. Rune provides first class support for defining, keeping track of, and loading realationships between records.

Out of the box, Rune supports three kinds of relationships, represented by property wrappers `@BelongsTo`, `@HasMany`, and `@HasOne`.

## BelongsTo

A `BelongsTo` is the simplest kind of relationship. It represents the child of a 1-1 or 1-M relationship. The child of a 1-1 or 1-M typically has a column referencing the primary key of another table.

With Alchemy, you can define a belongs to relationship with the `@BelongsTo` property wrapper.

```swift
struct Person: Model {
    static let tableName = "people"

    var id: Int?
    let name: String
}

struct Pet: Model {
    static let tableName = "pets"

    var id: Int?
    let name: String

    @BelongsTo
    var owner: Person
}
```

This signifies that a column on `Pet` references the id column of `Person`. By default, Alchemy will store the `id` type of `Person` (`Int`) into a column named `owner_id` on the `pets` table.

Creating a new `Pet` would look like...

```swift
let owner: Person = ...
let pet = Pet(
    name: "Fido", 
    owner: .init(owner) // Note that this is passing in a `BelongsTo` initialized containing a `Person`.
)
pet.save() // Save the pet; `owner.id` will be stored on the `owner_id` column of the `pets` table.
```

### Custom Column Suffix

By default, `BelongsTo` relationships have the parent `Model`'s id mapped to a table column called `\(propertyName)Id`. Above, this was converted to `owner_id` because default `Model`s convert their properties to snake case.

If you'd like to have a custom `BelongsTo` column suffix, you may do so by overriding the `Model.belongsToColumnSuffix` static property.

```swift
struct Pet: Model {
    static let belongsToColumnSuffix = "ParentId"
    ...
}
```

This would result in the `owner` property being mapped to column `owner_parent_id`.

## Eager Loading Relationships

In order to access a relationship property of a queried `Model`, you need to load that relationship first. You can "eager load" it using the `.with()` function on a `ModelQuery`. Eager loading refers to preemptively, or "eagerly", loading a relationship before it is used.

This function takes a `KeyPath` to a relationship and runs a query to fetch it when the initial query is finished.

```swift
Pet.query()
    .with(\.$owner)
    .getAll()
    .whenSuccess { pets in
        for pet in pets {
            print("Pet \(pet.name) has owner \(pet.owner.name)")
        }
    }
```

You may chain any number of eager loads from a `Model` using `.with()`.

```swift
Pets.query()
    .with(\.$owner)
    .with(\.$otherRelationship)
    .with(\.$yetAnotherRelationship)
    .getAll()
```

**Caveat 1**: The `.with()` function takes a `KeyPath` to a _relationship_ not a `Model`, so be sure to preface your key path with a `$`.

**Caveat 2**: For the eager loading to work, this query must be loaded with a function that decodes the `Model` type, such as `getAll()` or `getFirst()`. If the query is finished with a function that results in a `EventLoopFuture<[DatabaseRow]>` return type, there won't be a way to know how to eager load. Be sure that when eager loading, you finish the query with a function that automatically decodes the `Model` type.

**Caveat 3**: If you access a relationship before it's loaded, the program will `fatalError`. Be sure a relationship is loaded with eager loading before accessing it!

### Nested Eager Loading

You may want to load relationships on your eager loaded relationship `Model`s. You can do this with the second, closure argument of `with()`.

Consider three relationships, `Homework`, `Student`, `School`. A `Homework` belongs to a `Student` and a `Student` belongs to a `School`.

You might represent them in a database like so

```swift
struct Homework: Model {
    ...

    @BelongsTo
    var student: Student
}

struct Student: Model {
    ...
    
    @BelongsTo
    var school: School
}

struct School: Model {
    ...
}
```

To load all these relationships when querying `Homework`, you can use nested eager loading like so

```swift
Homework.query()
    .with(\.$student) { student in
        student.with(\.$school)
    }
    .getAll()
    .whenSuccess { homeworks in
        for homework in homeworks {
            // Can safely access `homework.student` and `homework.student.school`
        }
    }
```

## HasMany

A "HasMany" relationship represents the Parent side of a 1-M or a M-M relationship.

/// JOSH YOU WERE HERE

### Has Many Through

### Has Many Via

## HasOne

A "HasOne" relationship represents the Parent side of a 1-1 relationship. It property wrapper, `@HasOne`, functions almost identical to a `@HasMany`, except that it's wrapped type is either `Model?` or `Model`, instead of `[Model]`.

It can be initialized with the same two initializers as `@HasMany`.

```swift
struct Driver {
    @HasOne(this: "license", to: \.$owner, keyString: "owner_id")
    var license: License

    @HasOne(
        named: "vaccines",
        from: \PetVaccine.$pet,
        to: \.$vaccine,
        fromString: "pet_id",
        toString: "vaccine_id"
    )
    var car: Car
}
```

_Next page: [Security](7_Security.md)_

_[Table of Contents](/Docs)_