import Alchemy
import Foundation
import NIO

struct PetsController {
    func getUsers(_ req: HTTPRequest) -> EventLoopFuture<[User]> {
        User.query()
            .with(\.$pet)
            .with(\.$pets)
            .getAll()
    }
    
    func createUser(_ req: HTTPRequest) -> EventLoopFuture<User> {
        let user = User(id: nil, name: "Josh")
        return user.save()
            .map { user }
    }
    
    func getPets(_ req: HTTPRequest) -> EventLoopFuture<[Pet]> {
        Pet.query()
            .with(\.$owner)
            .with(\.$vaccines)
            .getAll()
    }
    
    func createPet(_ req: HTTPRequest) -> EventLoopFuture<Pet> {
        let owner = User(id: 1, name: "Josh")
        let pet = Pet(id: nil, name: "Fido", owner: .init(owner))
        return pet.save().map { pet }
    }
    
    func vaccinate(_ req: HTTPRequest) throws -> EventLoopFuture<Void> {
        let petID = try Int(try req.pathComponent(for: "pet_id")).unwrap(or: PetError("not int"))
        let vaccineID = try Int(try req.pathComponent(for: "vaccine_id")).unwrap(or: PetError("not int"))
        
        return PetVaccine(pet: .init(petID), vaccine: .init(vaccineID))
            .save()
    }
}

struct PetError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}
