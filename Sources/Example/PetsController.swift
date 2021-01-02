import Alchemy
import Foundation
import NIO

struct PetsController {
    func getOwners(_ req: Request) -> EventLoopFuture<[Owner]> {
        Owner.query()
            .with(\.$license)
            .with(\.$pets) {
                $0.with(\.$vaccines)
            }
            .getAll()
    }
    
    func createOwner(_ req: Request) throws -> EventLoopFuture<Owner> {
        Owner(name: UUID().uuidString).save()
    }
    
    func createLicense(_ req: Request) throws -> EventLoopFuture<License> {
        License(code: UUID().uuidString, owner: .init(0)).save()
    }
    
    func getPets(_ req: Request) -> EventLoopFuture<[Pet]> {
        Pet.query()
            .with(\.$owner)
            .with(\.$vaccines)
            .getAll()
    }
    
    func createPet(_ req: Request) -> EventLoopFuture<Pet> {
        Pet(name: UUID().uuidString, owner: .init(0)).save()
    }
    
    func vaccinate(_ req: Request) throws -> EventLoopFuture<Void> {
        return PetVaccine(pet: .init(0), vaccine: .init(0))
            .save()
            .voided()
    }
}

struct PetError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}
