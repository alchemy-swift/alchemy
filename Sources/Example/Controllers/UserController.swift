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
    
    func route(_ app: Application) {
        app
            // Get the current user
            .on(.GET, at: "/user") { request -> UserDTO in
                // `TokenAuthMiddleware` sets the `User` on the
                // incoming request, so all we have to do is
                // `Request.get` it.
                let user = try request.get(User.self)
                return UserDTO(id: try user.getID(), name: user.name, email: user.email)
            }
            // Logout the current user by deleting their token
            .on(.GET, at: "/logout") {
                // Since `TokenAuthMiddleware` sets a token on this
                // request, all we have to do is delete that token.
                try $0.get(UserToken.self).delete()
            }
    }
}
