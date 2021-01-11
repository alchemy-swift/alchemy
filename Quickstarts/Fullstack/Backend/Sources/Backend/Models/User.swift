import Alchemy

struct User: Model {
    static var tableName: String = "users"
    
    var id: Int?
    var name: String
    var email: String
    // Never store plaintext passwords!
    var hashedPassword: String
    
    // This User has many `Todo`s through the Todo's `user` property.
    // This is a 1-M relationship.
    @HasMany(to: \.$user)
    var todos: [Todo]
    
    // This User has many `Tag`s through the Tag's `user` property.
    // This is also a 1-M relationship.
    @HasMany(to: \.$user)
    var tags: [Tag]
}
