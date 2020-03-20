# Overview

Levels of abstraction:

1. `Database` represents a database
2. `Table` thin swift layer on top of actual DB tables
3. ``

## Relationship Scratch

Probably need everything through functions so we can get the type of `Self` for type checking.

### Need keys?
Parent of 1-1 (no key)
Child of 1-1 (key)
One of 1-M (no key)
Many of 1-M (key)
Many of M-M (no key)

### Need Relationship abstraction to:
1. General type for cool operations (like append, remove, associate)
2. Allow for eager loading
3. Define the method of access (i.e. a simple foreign key, pivot table, or a foreign key mapped through a few tables)
4. Interpret whether a foreign key is needed or not, during setup
5. 

### Options
1. Single property wrappers (@Relationship)
2. Multiple property wrappers
    A. @HasOne, @HasMany, BelongsToOne, ManyToMany
    B. @Parent, @Child, @Sibling
3. Generic Type (Relationship<Type>)

**PropertWrapper**
Cons:
- Can't be applied to computed vars, so all logic would have to be done in property wrapper init
- Can't access `Self` to enforce (jk, can through typealias on protocol extension)
- Can't be in an extension (not very swifty :( )
- Can't share models between client & server

**Generic Type Through Computed Vars**
Cons:
- Can't eager load computed properties (IMO this alone is enough to go the property wrapper route; would need a separate, stored type for eager loads. Or some confusing behavior around some Relationships being eagerly loadable and some not)

// Relationships [Parent, Child, Many]
// 1. Has One (parent of 1-1)
// 2. Belongs to (child of 1-1, child of 1-M)
// 3. Has Many (parent of 1-M)
// 4. Many (M-M)

/// `@HasOne` (1-1 Parent)
/// `@HasMany` (1-M Parent)
/// `@BelongsToOne` (1-1, 1-M Child)
/// `@ManyToMany` (M-M Either Side)

/// Consider a Database with tables `Travler`, `Country`, `Passport`
///
/// Traveler <-> Country: `M-M`.
/// Country <-> Passport: `1-M`.
/// Traveler <-> Passport: `1-1`.
///
///
/// `@One var traveler: Traveler`
/// `@One var passport: Passport`
/// `@One var passports: [Passport]`
/// `@Many var travelers: [Traveler]`
/// `@Many var countries: [Country]`

@propertyWrapper
struct One<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Many<T>: Codable where T: Codable {
    var wrappedValue: T

//    /// This is the `Many` of a OneToMany relationship.
//    init(via: KeyPath) {
//
//    }
}

