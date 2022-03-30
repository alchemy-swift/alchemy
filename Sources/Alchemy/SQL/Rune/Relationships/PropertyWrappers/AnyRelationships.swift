// Appendable to a `ModelQuery`; async throw runs on results before returning.
protocol EagerLoadableProperty: ModelProperty {
    // Downside;
    // 1. Must be in order
    // 2. Must be same length
    static func load(values: [PartialLoad<Self>]) async throws -> [Self]
}

struct PartialLoad<T: EagerLoadableProperty> {
    let row: SQLRow
    let initialValue: T
}

// Relationship crud is a separate beast; all queries on the relationship.
// user.$todos.append(moreTodos)
protocol Relationship2: EagerLoadableProperty {
    associatedtype From: Model
    associatedtype To: Model
    
    var mapping: RelationshipMapping<To, From> { get }
    
    func get() -> To // load in this case?
    func add() // adds one or more
    func remove() // removes the given ones
    func update() // updates to the given ones? might be tricky
}
