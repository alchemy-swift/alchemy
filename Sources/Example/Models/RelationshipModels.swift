import Alchemy

enum PetType: Int, ModelEnum {
    case dog, cat
}

struct Owner: Model {
    static var tableName: String = "owners"
    
    var id: Int?
    let name: String
    
    @HasMany(this: "pets", to: \.$owner)
    var pets: [Pet]
}

struct License: Model {
    static var tableName: String = "licenses"
    
    var id: Int?
    var code: String
    
    @BelongsTo
    var owner: Owner
}

struct Pet: Model {
    static var tableName: String = "pets"
    
    var id: Int?
    let name: String
    
    @BelongsTo
    var owner: Owner
    
    @HasMany(named: "vaccines", from: \PetVaccine.$pet, to: \.$vaccine)
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
