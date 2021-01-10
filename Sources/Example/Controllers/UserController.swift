import Alchemy

struct UsersController: Controller {
    /// A DTO representing the user. While we could directory send
    /// back the `User` model object, it contains the hashed
    /// password which should never be sent to the client.
    private struct UserDTO: Codable {
        let id: Int
        let name: String
        let email: String
    }
    
    /// A DTO containing info needed for creating a tag.
    private struct TagCreateDTO: Codable {
        let name: String
        let color: TagColor
    }
    
    func route(_ app: Application) {
        app
            // Get the current user
            .get("/user") { request -> UserDTO in
                // `TokenAuthMiddleware` sets the `User` on the
                // incoming request, so all we have to do is
                // `Request.get` it.
                let user = try request.get(User.self)
                return UserDTO(id: try user.getID(), name: user.name, email: user.email)
            }
            // Get the tags of this user.
            .get("/user/tag") { request -> EventLoopFuture<[Tag]> in
                let userID = try request.get(User.self).getID()
                return Tag.query()
                    .where("user_id" == userID)
                    .allModels()
            }
            // Create a tag for this user.
            .post("/user/tag") { request -> EventLoopFuture<Tag> in
                let user = try request.get(User.self)
                let dto: TagCreateDTO = try request.decodeBody()
                // Create and save a new tag based on the request
                // information.
                return Tag(name: dto.name, color: dto.color, user: .init(user))
                    .save()
            }
            // Logout the current user by deleting their token
            .post("/logout") {
                // Since `TokenAuthMiddleware` sets a token on this
                // request, all we have to do is delete that token.
                try $0.get(UserToken.self).delete()
            }
    }
}
