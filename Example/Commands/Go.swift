import Alchemy

struct Go: Command {
    static var _commandName: String = "go"

    func start() async throws {
        let count = try await DB.table("migrations")
            .log()
            .where("name" == "add_cache_migration" && "name" == "add_stuff_migration" || "name" != "add_stuff_migration")
            .count()
        print("Got \(count)")
//        let rows = try await DB.table("migrations").select()
//        print(rows.count)
    }

    func testRelationships() {
//        let user = try await User.query()
//            .with(\.posts.comments.likes)
//            .with {
//                $0.posts.with {
//                    $0.comments.with {
//                        $0.likes
//                    }
//                }
//            }
//            .with(\.tokens)
//            .where("id" == "user_1")
//            .first()!
//
//        let posts = try await user.posts()
//        let comments = try await posts[0].comments()
//        _ = try await comments[0].likes()
//        _ = try await user.posts.comments.likes()
//        let _comments: [Comment] = try await user.posts.comments.get()
//        let _likes: [Like] = try await user.posts.comments.likes.get()
//        let _likes1: [Like] = try await user.posts.comments.likes1.get()
//        let _comments: [Comment] = try await user.posts.comments.get()
//        let _comments1: [Comment] = try await user.posts.comments1.get()
//        let posts = try await user.posts()
//        let tokens = try await user.tokens()
//        let throughTokens = try await posts.first!.tokens()
//        let comments = try await user.comments()
//        let friends = try await user.friends()
//        let likes = try await user.likes()
//        let owner = try await likes.first!.postOwner()
    }
}

struct User: Model {
    var id: PK<String> = .new
    let name: String
    let age: Int

    var tokens: HasMany<UserToken> {
        hasMany()
    }

    var posts: HasMany<Post> {
        hasMany()
    }

    var comments: HasManyThrough<Comment> {
        hasMany().through("posts")
    }

    var likes: HasManyThrough<Like> {
        hasMany().through("posts").through("comments")
    }

    var friends: BelongsToMany<User> {
        belongsToMany(pivot: "friends", pivotFrom: "user_a", pivotTo: "user_b")
    }
}

struct UserToken: Model {
    var id: PK<String> = .new
    let token: String
    let userId: String

    var user: BelongsTo<User> {
        belongsTo()
    }
}

struct Post: Model {
    var id: PK<String> = .new
    let title: String
    let userId: String

    var comments: HasMany<Comment> {
        hasMany()
    }

    var comments1: HasOne<Comment?> {
        hasOne()
    }

    var tokens: HasManyThrough<UserToken> {
        hasMany(from: "user_id").through("users", from: "id")
    }
}

struct Comment: Model {
    var id: PK<String> = .new
    let text: String
    let userId: String

    var post: BelongsTo<Post> {
        belongsTo()
    }

    var likes: HasMany<Like> {
        hasMany()
    }

    var likes1: HasOne<Like> {
        hasOne()
    }

    var postOwner: BelongsToThrough<User> {
        belongsTo().through("posts")
    }
}

struct Like: Model {
    var id: PK<String> = .new
    let commentId: String
    let userId: String

    var postOwner: BelongsToThrough<User> {
        belongsTo().through("comments").through("posts")
    }
}

struct AddStuffMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("users") {
            $0.string("id").primary()
            $0.string("name")
            $0.int("age")
        }

        try await db.createTable("posts") {
            $0.string("id").primary()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("title")
        }

        try await db.createTable("user_tokens") {
            $0.string("id").primary()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("token")
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("posts")
        try await db.dropTable("user_tokens")
        try await db.dropTable("users")
    }
}

struct AddStuff2Migration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("friends") {
            $0.increments("id").primary()
            $0.string("user_a").references("id", on: "users").notNull()
            $0.string("user_b").references("id", on: "users").notNull()
        }

        try await db.createTable("comments") {
            $0.string("id").primary()
            $0.string("post_id").references("id", on: "posts").notNull()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("text")
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("friends")
        try await db.dropTable("comments")
    }
}

struct AddStuff3Migration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("likes") {
            $0.string("id").primary()
            $0.string("comment_id").references("id", on: "comments").notNull()
            $0.string("user_id").references("id", on: "users").notNull()
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("likes")
    }
}
