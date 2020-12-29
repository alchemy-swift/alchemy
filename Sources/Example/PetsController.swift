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
    
    func createUser(_ req: HTTPRequest) throws -> EventLoopFuture<User> {
        User(bmi: 20.0, email: "josh@test.com", age: 27, isPro: true, createdAt: Date(),
             passwordHash: try Bcrypt.hash("password"), parent: nil)
            .save()
    }
    
    func getPets(_ req: HTTPRequest) -> EventLoopFuture<[Pet]> {
        Pet.query()
            .with(\.$owner)
            .with(\.$vaccines)
            .getAll()
    }
    
    func createPet(_ req: HTTPRequest) -> EventLoopFuture<Pet> {
        Pet(id: nil, name: "Melvin", type: .dog, owner: .init(UUID()))
            .save()
    }
    
    func vaccinate(_ req: HTTPRequest) throws -> EventLoopFuture<Void> {
        let petID = try Int((req.pathParameter(named: "pet_id")?.stringValue ?? ""))
                                .unwrap(or: PetError("not int"))
        let vaccineID = try Int((req.pathParameter(named: "vaccine_id")?.stringValue ?? ""))
                                    .unwrap(or: PetError("not int"))
        
        return PetVaccine(pet: .init(petID), vaccine: .init(vaccineID))
            .save()
            .voided()
    }
}

struct PetError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}
