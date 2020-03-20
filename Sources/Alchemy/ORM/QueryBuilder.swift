// MARK: - Examples

// MARK: - Relationship Examples
/// CRUD Use Cases:
/// Read:
/// 1. Many to many: `.linked(using: JunctionTable)`
/// 2. One to many: `.linked(using: KeyPath)`
/// 3. One to one: `.linked(using: KeyPath).first()` (should the be a more explicit one liner?)
/// 4. Intermediary: chain `.linked(using: ...)` methods.
/// 5. Inverses of the above: calling `.linked(using: ...)` on the child instead of the parent?
extension User {
    // All `Comment`s from `Todo`s where the `owner` is `self`
    var comments: Relationship<[Comment]> {
        self.related(using: \Todo.owner)
            .linked(using: \Comment.todo)
    }

    // All `Tag`s on a `User`s `Todo`s
    var tags: Relationship<[Tag]> {
        self.related(using: \Todo.owner)
            .linked(using: JunctionTables.todoTags)
    }
}

/// Create:
/// 1. Many to many
/// 2. One to many
/// 3. One to one:
extension User {
    /// Many to many
    func addFriend(user: User) {

    }
}

// MARK: - Implementation

struct Relationship<Result> {
    // Call when you want to kick off the query
    func all() -> Future<Result> {
        fatalError()
    }

    func first() -> Future<Result?> {
        fatalError()
    }

    init(_ value: Result) {

    }
}

extension _Relation {
    
}

extension Model {
    // Alt names: `linked` `associated` `related` `{verb}Parent/Child`

    // Read
    func related<T: Model>(using junction: JunctionTable<Self, T>) -> Relationship<[T]> {
        // Filter across the junction table for objects of type T where the id key == `self.id`
        Relationship([])
    }

    func related<T: Model>(using foreignKey: KeyPath<T, Self>) -> Relationship<[T]> {
        // Filter across the T table for objects where `id` == `keyPathValue`
        Relationship([])
    }

    // Create
    func addRelation<T: Model>(child: T, using junction: JunctionTable<Self, T>) -> Relationship<T> {
        // Create child & junction table entry referencing self
        Relationship(child)
    }

    func addRelation<T: Model>(using foreignKey: KeyPath<T, Self>) -> Relationship<[T]> {
        // Create child with self as the key
        Relationship([])
    }
}

extension _Relation {
    // Alt names: `associated` `related`

    /// Shorthand for if the User doens't want a bunch of relationship properties. Basically an anonymous
    /// relationship for intermediary ones.

    func through<T: Model>(table: JunctionTable<From.Value, To.Value>) -> From.Value.Relation<T> {
        // Filter across the junction table for objects of type T where the id key == `self.id`
        fatalError()
    }

    func through<T: Model>(table: JunctionTable<To.Value, From.Value>) -> From.Value.Relation<T> {
        // Filter across the junction table for objects of type T where the id key == `self.id`
        fatalError()
    }

    func through<T: Model>(theirKey: KeyPath<T, To.Value>) -> From.Value.Relation<T> {
        // Filter across the T table for objects where `id` == `keyPathValue`
        fatalError()
    }

    func through<T: RelationAllowed>(relation: KeyPath<To, _Relation<To, T>>)
        -> From.Value.Relation<T.Value>
    {
        fatalError()
    }
}

/// Array versions of above
extension Relationship where Result: Sequence, Result.Element: Model {
    func linked<T: Model>(using junction: JunctionTable<Result.Element, T>) -> Relationship<[T]> {
        Relationship<[T]>([])
    }

    func linked<T: Model>(using foreignKey: KeyPath<T, Result.Element>) -> Relationship<[T]> {
        Relationship<[T]>([])
    }
}
