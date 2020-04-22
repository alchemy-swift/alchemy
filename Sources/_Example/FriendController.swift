import Alchemy

struct FriendsController {
    func add(req: HTTPRequest, current: User) throws -> Void {
        let dto = try req.validate(AddFriendDTO.self)
    }

    func remove(req: HTTPRequest, current: User) throws -> Void {
        let dto = try req.validate(RemoveFriendDTO.self)
    }

    func message(req: HTTPRequest, current: User) throws -> Void {
        let dto = try req.validate(MessageFriendDTO.self)
    }
}

struct AddFriendDTO: RequestCodable {}
struct RemoveFriendDTO: RequestCodable {}
struct MessageFriendDTO: RequestCodable {}
