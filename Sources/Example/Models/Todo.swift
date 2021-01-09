import Alchemy

struct Todo: Model {
    static var tableName: String = "todos"
    
    var id: Int?
    var name: String
    var isComplete: Bool
    
    @BelongsTo
    var user: User
    
    // This `Todo` has many tags through `TodoTag`. This is a M-M
    // relationship.
    @HasMany(from: \TodoTag.$todo, to: \.$tag)
    var tags: [Tag]
}
