import Alchemy

struct AuthController: Controller {
    private struct SignupDTO: Codable {
        let name: String
        let email: String
        let password: String
    }

    private struct LoginDTO: Codable {
        let email: String
        let password: String
    }
    
    func route(_ router: Router) {
        router
            .on(.POST, at: "/signup") { req -> EventLoopFuture<User> in
                let dto: SignupDTO = try req.getBody(encoding: .json)
                return User.ensureNotExists("email" == dto.email, else: HTTPError(.conflict))
                    .flatMap {
                        Bcrypt.hashAsync(dto.password)
                            .map { User(name: dto.name, email: dto.email, hashedPassword: $0) }
                            .flatMap { $0.save() }
                    }
            }
            .on(.POST, at: "/login") { req -> EventLoopFuture<UserToken> in
                let dto: LoginDTO = try req.getBody(encoding: .json)
                return User.unwrapFirstWhere("email" == dto.email, or: HTTPError(.unauthorized))
                    .map { UserToken(value: UUID().uuidString, createdAt: Date(), user: .init($0)) }
                    .flatMap { $0.save() }
            }
    }
}
