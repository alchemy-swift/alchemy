import Alchemy

struct FriendsController {
    func add(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(AddFriendDTO.self)
    }

    func remove(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(RemoveFriendDTO.self)
    }

    func message(req: HTTPRequest) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(MessageFriendDTO.self)
        let ep = FriendAPI().friends
    }
}

struct AddFriendDTO: EndpointRequest {}
struct RemoveFriendDTO: EndpointRequest {}
struct MessageFriendDTO: EndpointRequest {}

struct FriendAPI {
    @GET("/friends")
    var friends: Endpoint<AddFriendDTO, Empty>
}

class FriendAPI2: EndpointGroup {
    @GET("/friends")
    var friends: Endpoint<AddFriendDTO, Empty>
}
