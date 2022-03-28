// Protocol
// 1. Store value in db
// 2. Load value from db
// Eager loading?
// - run complicated work on batches of data so it's simpler... only applies to
//   relationships? Could easily be custom done? Add a "run after query"
//   protocol? Custom map; take results and do something to them.

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

protocol Timestamps {
    // Might not need to require these? Can just update SQLRow.
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}
