import Alchemy
import Shared

struct AuthController: Controller {
    let api = AuthAPI()
    
    func route(_ app: Application) {
        app
            .on(self.api.login) { req, content in
                // First, ensure a user with the provided email
                // exists. If it doesn't return a 401.
                return User.unwrapFirstWhere("email" == content.dto.email, or: HTTPError(.unauthorized))
                    // Then, confirm the provided password matches
                    // the given password, using Bcrypt. Note it
                    // runs asynchronously so as not to block.
                    .flatMap { user -> EventLoopFuture<User> in
                        Bcrypt.verifyAsync(plaintext: content.dto.password, hashed: user.hashedPassword)
                            .flatMapThrowing { passwordIsValid in
                                if passwordIsValid {
                                    // If the password is valid,
                                    // return the user fetched from
                                    // above.
                                    return user
                                } else {
                                    // If it isn't valid, throw a 401.
                                    throw HTTPError(.unauthorized)
                                }
                            }
                    }
                    // Turn the user into a new `UserToken` with which
                    // the client can use to authorize in the future.
                    .map { UserToken(value: UUID().uuidString, createdAt: Date(), user: .init($0)) }
                    // Save the token.
                    .flatMap { $0.save() }
                    // Map the token to a DTO and return.
                    .map { AuthAPI.TokenDTO(value: $0.value) }
            }
            .on(self.api.signup) { req, content in
                // First, ensure a user doesn't exist with the same
                // email. If it does, return a 409.
                let conflictError = HTTPError(.conflict, message: "An account with this email already exists.")
                return User.ensureNotExists("email" == content.dto.email, else: conflictError)
                    .flatMap {
                        // Asynchronously (so as not to block the
                        // current `EventLoop`) hash the provided
                        // password using Bcrypt.
                        Bcrypt.hashAsync(content.dto.password)
                            .map { User(name: content.dto.name, email: content.dto.email, hashedPassword: $0) }
                            .flatMap { $0.save() }
                    }
                    // Create an auth token for the new user.
                    .flatMap { UserToken(user: .init($0)).save() }
                    // Map the token to a DTO and return.
                    .map { AuthAPI.TokenDTO(value: $0.value) }
            }
    }
}
