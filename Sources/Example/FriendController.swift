import Alchemy

struct FriendsController {
    func add(req: Request) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(AddFriendDTO.self)
    }

    func remove(req: Request) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(RemoveFriendDTO.self)
    }

    func message(req: Request) throws -> Void {
        let authedUser = try req.get(User.self)
        let dto = try req.decodeRequest(MessageFriendDTO.self)
        let ep = FriendAPI().add
    }
}

struct AddFriendDTO: EndpointRequest {
    @Path        var userID: String
    @URLQuery   var number: Int
    @Header      var value: String
    @Body(.json) var obj: TestObj
}

struct TestObj: Codable {
    let string: String
}

struct RemoveFriendDTO: EndpointRequest {}
struct MessageFriendDTO: EndpointRequest {}

final class FriendAPI: EndpointGroup {
    @POST("/friends/:userID")
    var add: Endpoint<AddFriendDTO, Empty>
}
