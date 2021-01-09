import Alchemy

struct User: Model {
    static var tableName: String = "users"
    
    var id: Int?
    var name: String
    var email: String
    var hashedPassword: String
    
    @HasMany(to: \.$user)
    var todos: [Todo]
    
    @HasMany(to: \.$user)
    var tags: [Tag]
}
