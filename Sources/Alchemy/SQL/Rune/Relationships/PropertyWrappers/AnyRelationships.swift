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

protocol Timestamps {
    // Might not need to require these? Can just update SQLRow.
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}
