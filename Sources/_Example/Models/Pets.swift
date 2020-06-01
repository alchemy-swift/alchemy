import Alchemy

struct User: Model, Authable {
    static var tableName: String = "users"
    
    let id: Int?
    let name: String
    
    @HasOne(this: "pet", to: \.$owner, keyString: "owner_id")
    var pet: Pet?
    
    @HasMany(this: "pets", to: \.$owner, keyString: "owner_id")
    var pets: [Pet]
}

enum PetType: Int, Codable {
    case dog, cat
}

struct Pet: Model {
    static var tableName: String = "pets"
    
    let id: Int?
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
    
    let id: Int?
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
