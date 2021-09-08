# Rune: Relationships

- [Relationship Types](#relationship-types)
    * [BelongsTo](#belongsto)
    * [HasMany](#hasmany)
    * [HasOne](#hasone)
    * [HasMany through](#hasmany-through)
    * [HasOne through](#hasone-through)
    * [ManyToMany](#manytomany)
- [Eager Loading Relationships](#eager-loading-relationships)
    * [Nested Eager Loading](#nested-eager-loading)

Relationships are an important part of an SQL database. Rune provides first class support for defining, keeping track of, and loading relationships between records.

## Relationship Types

Out of the box, Rune supports three categories of relationships, represented by property wrappers `@BelongsTo`, `@HasMany`, and `@HasOne`.

Consider a database with tables `users`, `todos`, `tags`, `todo_tags`.

```
users
    - id

todos
    - id
    - user_id
    - name

tags
    - id
    - name

todo_tags
    - id
    - todo_id
    - tag_id
```

### BelongsTo

A `BelongsTo` is the simplest kind of relationship. It represents the child of a 1-1 or 1-M relationship. The child typically has a column referencing the primary key of another table.

```swift
struct Todo: Model {
    @BelongsTo var user: User
}
```

Given the `@BelongsTo` property wrapper and types, Rune will infer a `user_id` key on Todo and an `id` key on `users` when eager loading. If the keys differ, for example `users` local key is `my_id` you may access the `RelationshipMapping` in `Model.mapRelations` and override either key with `to(...)` or `from(...)`. `to` overrides the key on the destination of the relation, `from` overrides the key on the model the relation is on.

```swift
struct Todo: Model {
    @BelongsTo var user: User

    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        // config takes a `KeyPath` to a relationship and returns its mapping
        mapper.config(\.$user).to("my_id")
    }
}
```

### HasMany

A "HasMany" relationship represents the Parent side of a 1-M or a M-M relationship.

```swift
struct User: Model {
    @HasMany var todos: [Todo]
}
```

Again, Alchemy is inferring a local key `id` on `users` and a foreign key `user_id` on `todos`. You can override either using the same `mapRelations` function.

```swift
struct User: Model {
    @HasMany var todos: [Todo]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$todos).from("my_id").to("parent_id")
    }
}
```

### HasOne

Has one, a has relationship where there is only one value, functions the same as `HasMany` except it wraps single value, not an array. Overriding keys works the same way.

```swift
struct User: Model {
    @HasOne var car: Car
}
```

### HasMany through

The `.through(...)` mapping provides a convenient way to access distant relations via an intermediate relation.

Consider tables representing a CI system `user`, `projects`, `workflows`.

```
users
    - id

projects
    - id
    - user_id

workflows
    - id
    - project_id
```

Given a user, you could access their workflows, through the project table by using the `through(...)` function. 

```swift
struct User: Model {
    @HasMany var workflows: [Workflow]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$workflows).through("projects")
    }
}
```

Again, Alchemy assumes all the keys in this relationship based on the types of the relationship, and the intermediary table name. You can override this using the same `.from` & `.to` functions and you can override the intermediary table keys with the `from` and `to` parameters of `through`.

```swift
struct User: Model {
    @HasMany var workflows: [Workflow]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$workflows)
            .from("my_id")
            .through("projects", from: "the_user_id", to: "_id")
            .to("my_project_id")
    }
}
```

### HasOne through

The `.through(...)` mapping can also be applied to a `HasOne` relationship. It functions the same, with overrides available for `from`, `throughFrom`, `throughTo`, and `to`.

```swift
struct User: Model {
    @HasOne var workflow: Workflow
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$workflow).through("projects")
    }
}
```

### ManyToMany

Often you'll have relationships that are defined by a pivot table containing references to each side of the relationship. You can use the `throughPivot` function to define a `@HasMany` relationship to function this way.

```swift
struct Todo: Model {
    @HasMany var tags: [Tag]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$tags).throughPivot("todo_tags")
    }
}
```

Like `through`, keys are inferred but you may specify `from` and `to` parameters to indicate the keys on the pivot table. 

```swift
struct Todo: Model {
    @HasMany var tags: [Tag]
    
    static func mapRelations(_ mapper: RelationshipMapper<Self>) {
        mapper.config(\.$tags).throughPivot("todo_tags", from: "the_todo_id", to: "the_tag_id")
    }
}
```

## Eager Loading Relationships

In order to access a relationship property of a queried `Model`, you need to load that relationship first. You can "eager load" it using the `.with()` function on a `ModelQuery`. Eager loading refers to preemptively, or "eagerly", loading a relationship before it is used. Eager loading also solves the N+1 problem; if N `Pet`s are returned with a query, you won't need to run N queries to find each of their `Owner`s. Instead, a single, followup query will be run that finds all `Owner`s for all `Pet`s fetched.

This function takes a `KeyPath` to a relationship and runs a query to fetch it when the initial query is finished.

```swift
Pet.query()
    .with(\.$person)
    .getAll()
    .whenSuccess { pets in
        for pet in pets {
            print("Pet \(pet.name) has owner \(pet.person.name)")
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

**Warning 1**: The `.with()` function takes a `KeyPath` to a _relationship_ not a `Model`, so be sure to preface your key path with a `$`.

**Warning 2**: If you access a relationship before it's loaded, the program will `fatalError`. Be sure a relationship is loaded with eager loading before accessing it!

### Nested Eager Loading

You may want to load relationships on your eager loaded relationship `Model`s. You can do this with the second, closure argument of `with()`.

Consider three relationships, `Homework`, `Student`, `School`. A `Homework` belongs to a `Student` and a `Student` belongs to a `School`.

You might represent them in a database like so

```swift
struct Homework: Model {
    @BelongsTo var student: Student
}

struct Student: Model {
    @BelongsTo var school: School
}

struct School: Model {}
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

_Next page: [Security](7_Security.md)_

_[Table of Contents](/Docs#docs)_
