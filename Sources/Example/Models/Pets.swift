import Alchemy

struct UserJSON: Codable {
    let age: Int
    let name: String
}

struct User: Model, BasicAuthable {
    static var tableName: String = "users"
    static var usernameKeyString: String = "email"
    static var keyMappingStrategy: DatabaseKeyMappingStrategy { .convertToSnakeCase }
    
    var id: UUID?
    let bmi: Double
    let email: String
    let age: Int
    let isPro: Bool
    let createdAt: Date
    var someJSON: UserJSON?
    let passwordHash: String
    
    @BelongsTo
    var parent: User?
}

struct UserToken: Model, TokenAuthable {
    static var userKey: KeyPath<UserToken, BelongsTo<User>> = \.$user
    
    var id: Int?
    let value: String
    
    @BelongsTo
    var user: User
    
    @BelongsTo
    var user2: User?
    
    @HasMany
    var user3: [User]
    
    @HasOne
    var user4: User?
    
    @HasOne
    var user5: User
}
