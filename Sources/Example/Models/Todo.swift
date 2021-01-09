import Alchemy

struct Todo: Model {
    static var tableName: String = "todos"
    
    var id: Int?
    var name: String
    var isComplete: Bool
    
    @BelongsTo
    var user: User
    
    @HasMany(from: \TodoTag.$todo, to: \.$tag)
    var tags: [Tag]
}
