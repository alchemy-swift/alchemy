import Alchemy

struct User: Model, Authable {
    static var tableName: String = "users"
    
    let id: Int?
    let name: String
    
    @HasOne(this: "pet", to: "owner_id", via: \.$owner)
    var pet: Pet?
}

struct Pet: Model {
    static var tableName: String = "pets"
    
    let id: Int?
    let name: String
    
    @BelongsTo
    var owner: User
}
