# Rune: Relationships

- [BelongsTo](#belongsto)
  * [Custom Column Suffix](#custom-column-suffix)
- [Eager Loading Relationships](#eager-loading-relationships)
  * [Nested Eager Loading](#nested-eager-loading)
- [HasMany](#hasmany)
  * [One to Many](#one-to-many)
  * [Has Many Through](#has-many-through)
- [HasOne](#hasone)
- [HasRelationship Caveat](#hasrelationship-caveat)

Relationships are an important part of an SQL database. Rune provides first class support for defining, keeping track of, and loading relationships between records.

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

In order to access a relationship property of a queried `Model`, you need to load that relationship first. You can "eager load" it using the `.with()` function on a `ModelQuery`. Eager loading refers to preemptively, or "eagerly", loading a relationship before it is used. Eager loading also solves the N+1 problem; if N `Pet`s are returned with a query, you won't need to run N queries to find each of their `Owner`s. Instead, a single, followup query will be run that finds all `Owner`s for all `Pet`s fetched.

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

A "HasMany" relationship represents the Parent side of a 1-M or a M-M relationship. The method of resolving the relationship is defined in the initializer of the `@HasMany(...)` wrapper.

### One to Many

The parent of a 1-M relationship is typically the opposite side of a `@BelongsTo` relationship; there is some foreign key on a child Model that references this `Model`. With `Rune`, this can be represented with the following:

```swift
struct Owner: Model {
    ...

    @HasMany(via: \.$owner)
    var pets: [Pet]
}
```

In this case, `Pet` has an `@BelongsTo` relationship to `Owner`. By providing the `KeyPath` of that relationship, Rune has enough information to eager load the `Pet`s referencing this `Owner`. Eager loading a `@HasMany` is the same syntax as `@BelongsTo`.

```swift
Owner.query()
    .with(\.$pets)
    .getAll()
    .whenSuccess { owners in
        for owner in owners {
            print("Owner \(owner.name) has \(owner.pets.count) pets.")
        }
    }
```

Note, Rune is assuming the foreign key on the `Pet` model is the snake_cased name of the query type suffixed with `_id`. So, in this case, Rune assumes the foreign key column on the `Pet` model is `owner_id`.

You may override the foreign key column by passing an additional argument to the `@HasMany` initializer.

```swift
@HasMany(via: \.$owner, keyString: "owner_id")
var pets: [Pet]
```

### Has Many Through

`@HasMany` can also represent either side of a M-M relationship. This is a relationship where each side of the relationship may be linked to one or more Models on the other side, typically by a "Pivot table". For example, a `Student` may have multiple `Course`s and a `Course` may have multiple `Student`s. With Alchemy, this relationship behavior is also defined in the `@HasMany` initializer.

```swift
struct Student: Model {
    ...

    @HasMany(from: \StudentCourse.$student, to: \.$course)
    var courses: [Course]
}

struct Course: Model {
    ...

    @HasMany(from: \StudentCourse.$course, to: \.$student)
    var students: [Student]
}

struct StudentCourse: Model {
    ...

    @BelongsTo var student: Student
    @BelongsTo var course: Course
}
```

The `@HasMany` initializer is given two `KeyPath`s on a pivot table (in this case `StudentCourse`) and Rune is given enough information to eager load this relationship in a query.

```swift
Student.query()
    .with(\.$courses)
    .getAll() // `Student.courses` will be loaded.
```

Note that, once again, Rune is inferring the reference keys on the pivot table to be the snake_cased name of the type suffixed by "_id". In this case, `student_id` and `course_id`. Like before, you may provide custom key `String`s in the initializer.

```swift
struct Student: Model {
    ...

    @HasMany(
        from: \StudentCourse.$student, 
        to: \.$course, 
        fromKey: "student_id", 
        toKey: "course_id"
    )
    var courses: [Course]
}
```

## HasOne

A "HasOne" relationship represents the Parent side of a 1-1 relationship, either via a foreign key on another `Model` or a pivot table. `@HasOne`, functions almost identical to a `@HasMany`, except that it's wrapped type is either `Model?` or `Model`, instead of `[Model]`. This means that when eager loading, it just fetches the first item that matches the relationship query.

It can be initialized with the same two initializers as `@HasMany` & eager loaded in the same way.

```swift
struct Driver {
    @HasOne(to: \.$driver)
    var license: License

    @HasOne(from: \DriverCars.$driver, to: \.$car)
    var car: Car
}

Driver.query()
    .with(\.$license)
    .with(\.$car)
    .getAll()
    .whenSuccess { drivers in
        for driver in drivers {
            // `driver.license` and `driver.car` are loaded.
        }
    }
```

## HasRelationship Caveat

There is a niche caveat when eager loading `HasOne` and `HasMany` relationships. Eager loading them relies on caching load behavior. Without going into the implementation details, this means that if there are two of the same relationships, with the same type signatures, on the same `Model`, the eager loader won't know which eager loading behavior to use and the behavior will be undefined. 

This isn't a scenario you'll encounter much, if at all, but if you do have two "Has" relationships for which **all** the following are true...

1. they both wrap properties on the same `Model`

AND

2. they are the same type (both are `HasOne`, both are `HasMany`)

AND

3. they wrap the same type (i.e. both `User` or both `[User]` or both `User?`)

... you'll need to pass them both their wrapping property name in their initializer so that the eager loader can differentiate between the two.

```swift
struct Flight: Model {
    // BelongsTo<Person> - don't need `propertyName`; not a `HasOne` or `HasMany` relationship
    @BelongsTo
    var pilot: Person 

    // BelongsTo<Person> - don't need `propertyName`; not a `HasOne` or `HasMany` relationship
    @BelongsTo
    var copilot: Person 

    // HasOne<Person> - don't need `propertyName`; type signature is unique on this `Model`
    @HasOne(to: \.$crewLeadForFlight, keyString: "crew_lead_for_flight_id")
    var crewLead: Person 

    // HasOne<Person?> - don't need `propertyName`; type signature is unique on this `Model`
    @HasOne(to: \.$backupPilotForFlight, "backup_pilot_for_flight")
    var extraPilot: Person? 

    // HasMany<[Person]> - need `propertyName` because `crew` has the same type signature.
    @HasMany(propertyName: "passengers", from: \FlightPassengers.$flight, to: \.$person) 
    var passengers: [Person]

    // HasMany<[Person]> - need `propertyName` because `passengers` has the same type signature.
    @HasMany(propertyName: "crew", from: \FlightCrew.$flight, to: \.$person) 
    var crew: [Person]                                 
}
```

_Next page: [Security](7_Security.md)_

_[Table of Contents](/Docs#docs)_