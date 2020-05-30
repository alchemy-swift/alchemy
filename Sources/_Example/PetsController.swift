import Alchemy
import Foundation
import NIO

struct PetsController {
    func test() -> some CustomStringConvertible {
        ""
    }
    
    func getUsers(_ req: HTTPRequest) -> EventLoopFuture<[User]> {
        User.all()
    }
    
    func createUser(_ req: HTTPRequest) -> EventLoopFuture<User> {
        let user = User(id: nil, name: "Josh")
        return user.save()
            .map { user }
    }
    
    func getPets(_ req: HTTPRequest) -> EventLoopFuture<[Pet]> {
        Pet.all()
    }
    
    func createPet(_ req: HTTPRequest) -> EventLoopFuture<Pet> {
        let owner = User(id: 1, name: "Josh")
        let pet = Pet(id: nil, name: "Fido", owner: .init(owner))
        return pet.save().map { pet }
    }
}
