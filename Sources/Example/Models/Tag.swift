import Alchemy

enum TagColor: Int, ModelEnum {
    case red, green, blue, orange, purple
}

struct Tag: Model {
    static var tableName: String = "tags"
    
    var id: Int?
    var name: String
    var color: TagColor
    
    @BelongsTo
    var user: User
}
