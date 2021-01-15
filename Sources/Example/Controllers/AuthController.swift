import Alchemy

struct AuthController: Controller {
    // A DTO representing the data needed to create a new user.
    private struct SignupDTO: Codable {
        let name: String
        let email: String
        let password: String
    }

    // A DTO representing the data needed to login a user.
    private struct LoginDTO: Codable {
        let email: String
        let password: String
    }
    
    // A DTO representing the data in an auth token.
    private struct TokenDTO: Codable {
        let value: String
    }
    
    func route(_ app: Application) {
        app
            // Create a new user account
            .post("/signup") { req -> EventLoopFuture<TokenDTO> in
                let dto: SignupDTO = try req.decodeBody()
                // First, ensure a user doesn't exist with the same
                // email. If it does, return a 409.
                let conflictError = HTTPError(.conflict, message: "An account with this email already exists.")
                return User.ensureNotExists("email" == dto.email, else: conflictError)
                    .flatMap {
                        // Asynchronously (so as not to block the
                        // current `EventLoop`) hash the provided
                        // password using Bcrypt.
                        Bcrypt.hashAsync(dto.password)
                            .map { User(name: dto.name, email: dto.email, hashedPassword: $0) }
                            .flatMap { $0.save() }
                    }
                    // Create an auth token for the new user.
                    .flatMap { UserToken(user: .init($0)).save() }
                    // Map the token to a DTO and return.
                    .map { TokenDTO(value: $0.value) }
            }
            // Login with an existing account
            .post("/login") { req -> EventLoopFuture<TokenDTO> in
                let dto: LoginDTO = try req.decodeBody()
                // First, ensure a user with the provided email
                // exists. If it doesn't return a 401.
                return User.unwrapFirstWhere("email" == dto.email, or: HTTPError(.unauthorized))
                    // Then, confirm the provided password matches
                    // the given password, using Bcrypt. Note it
                    // runs asynchronously so as not to block.
                    .flatMap { user -> EventLoopFuture<User> in
                        Bcrypt.verifyAsync(plaintext: dto.password, hashed: user.hashedPassword)
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
                    .map { TokenDTO(value: $0.value) }
            }
    }
}
