import Alchemy

struct User: Model, BasicAuthable {
    static var tableName: String = "users"
    static var usernameKeyString: String = "email"
    
    var id: Int?
    let email: String
    let passwordHash: String
    let name: String
    
    @HasOne(this: "pet", to: \.$owner, keyString: "owner_id")
    var pet: Pet?
    
    @HasMany(this: "pets", to: \.$owner, keyString: "owner_id")
    var pets: [Pet]
}

struct UserToken: Model, TokenAuthable {
    static var userKey: KeyPath<UserToken, BelongsTo<User>> = \.$user
    
    var id: Int?
    let value: String
    
    @BelongsTo
    var user: User
}

enum PetType: Int, Codable {
    case dog, cat
}

struct Pet: Model {
    static var tableName: String = "pets"
    
    var id: Int?
    let name: String
    let type: PetType
    
    @BelongsTo
    var owner: User
    
    @HasMany(
        named: "vaccines",
        from: \PetVaccine.$pet,
        to: \.$vaccine,
        fromString: "pet_id",
        toString: "vaccine_id"
    )
    var vaccines: [Vaccine]
}

struct Vaccine: Model {
    static var tableName: String = "vaccines"
    
    var id: Int?
    let name: String
}

struct PetVaccine: Model {
    static var tableName: String = "pet_vaccines"
    
    var id: Int?
    
    @BelongsTo
    var pet: Pet
    
    @BelongsTo
    var vaccine: Vaccine
}
