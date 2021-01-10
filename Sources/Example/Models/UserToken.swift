import Alchemy

struct UserToken: Model, TokenAuthable {
    static var tableName: String = "user_tokens"
    // This informs `TokenAuthable` a couple of things;
    //
    // 1) What the related user model is, in this case `User`
    // 2) How to eager load `User`, given a `UserToken`.
    //
    // This way, `TokenAuthMiddleware` can automatically verify and
    // set a user on Request, based on the incoming `Authorization`
    // header.
    static var userKey: KeyPath<UserToken, BelongsTo<User>> = \.$user
    
    var id: Int?
    var value: String = UUID().uuidString
    var createdAt: Date = Date()

    @BelongsTo
    var user: User
}
