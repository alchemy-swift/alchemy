import Alchemy
import Shared

struct UserController: Controller {
    let api = UserAPI()
    
    func route(_ app: Application) {
        app
            // Get the current user
            .on(self.api.getUser) { req in
                // `TokenAuthMiddleware` sets the `User` on the
                // incoming request, so all we have to do is
                // `Request.get` it.
                .new(try req.get(User.self).toDTO())
            }
            // Get the tags of this user.
            .on(self.api.getTags) { req in
                let userID = try req.get(User.self).getID()
                return Tag.query()
                    .where("user_id" == userID)
                    .allModels()
                    .flatMapEachThrowing { try $0.toDTO() }
            }
            // Create a tag for this user.
            .on(self.api.createTag) { req, content in
                let user = try req.get(User.self)
                // Create and save a new tag based on the request
                // information.
                return Tag(name: content.dto.name, color: TagColor(rawValue: content.dto.color.rawValue)!, user: .init(user))
                    .save()
                    .flatMapThrowing { try $0.toDTO() }
            }
            // Logout the current user by deleting their token
            .on(self.api.logout) { req, content in
                // Since `TokenAuthMiddleware` sets a token on this
                // request, all we have to do is delete that token.
                try req.get(UserToken.self).delete()
            }
    }
}

extension Tag {
    func toDTO() throws -> UserAPI.TagDTO {
        UserAPI.TagDTO(
            id: try self.getID(),
            name: self.name,
            color: UserAPI.TagDTO.Color(rawValue: self.color.rawValue)!
        )
    }
}

extension User {
    func toDTO() throws -> UserAPI.UserDTO {
        UserAPI.UserDTO(id: try self.getID(), name: self.name, email: self.email)
    }
}
