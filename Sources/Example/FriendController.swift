import Alchemy

struct FriendsController {
    func add(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.validate(AddFriendDTO.self)
    }

    func remove(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.validate(RemoveFriendDTO.self)
    }

    func message(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.validate(MessageFriendDTO.self)
    }
}

struct AddFriendDTO: RequestCodable {}
struct RemoveFriendDTO: RequestCodable {}
struct MessageFriendDTO: RequestCodable {}
