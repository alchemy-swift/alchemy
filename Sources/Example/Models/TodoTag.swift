import Alchemy

struct TodoTag: Model {
    static var tableName: String = "todo_tags"
    
    var id: Int?
    
    @BelongsTo
    var todo: Todo
    
    @BelongsTo
    var tag: Tag
}
