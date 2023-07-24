import Alchemy

struct Go: Command {
    static var _commandName: String = "go"

    func start() async throws {

        /*
         Checklist

         1. DONE BelongsTo
         2. DONE HasOne
         3. DONE HasMany
         4. DONE HasManyThrough
         5. DONE HasOneThrough
         6. DONE BelongsToMany
         7. DONE BelongsToThrough
         8. DONE Add multiple throughs
         9. DONE Eager Loading
         10 DONE Nested eager loading
         11. DONE Add where to Relationship
         12. DONE Clean up key inference
         13. Clean up cache keying
         14. CRUD
         15. Subscript loading

         */

        let user = try await User.query()
            .with(\.posts) {
                $0.with(\.comments) {
                    $0.with(\.likes)
                }
            }
            .with(\.tokens)
            .where("id" == "user_1")
            .first()!
        let posts = try await user.posts()
        let tokens = try await user.tokens()
        let throughTokens = try await posts.first!.tokens()
        let comments = try await user.comments()
        let friends = try await user.friends()
        let likes = try await user.likes()
        let owner = try await likes.first!.postOwner()

//        let users = try await User
//            .query()
//            .with2(\.tokens)
//            .with2(\.posts.tokens)
//            .all()
//
//        for user in users {
//            print("> \(user.name)")
//            print(">> TOKENS")
//            for token in try await user.tokens() {
//                print(">>> \(token.token) of \(try await token.user().id ?? 0)") // try await token.user.posts.fetch().count
//            }
//
//            print(">> POSTS")
//            for post in try await user.posts() {
//                print(">>> \(post.title) count \(try await post.tokens().count)")
//            }
//        }
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
    func up(schema: Schema) {
        schema.create(table: "users") {
            $0.string("id").primary()
            $0.string("name")
            $0.int("age")
        }

        schema.create(table: "posts") {
            $0.string("id").primary()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("title")
        }

        schema.create(table: "user_tokens") {
            $0.string("id").primary()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("token")
        }
    }

    func down(schema: Schema) {
        schema.drop(table: "posts")
        schema.drop(table: "user_tokens")
        schema.drop(table: "users")
    }
}

struct AddStuff2Migration: Migration {
    func up(schema: Schema) {
        schema.create(table: "friends") {
            $0.increments("id").primary()
            $0.string("user_a").references("id", on: "users").notNull()
            $0.string("user_b").references("id", on: "users").notNull()
        }

        schema.create(table: "comments") {
            $0.string("id").primary()
            $0.string("post_id").references("id", on: "posts").notNull()
            $0.string("user_id").references("id", on: "users").notNull()
            $0.string("text")
        }
    }

    func down(schema: Schema) {
        schema.drop(table: "friends")
        schema.drop(table: "comments")
    }
}

struct AddStuff3Migration: Migration {
    func up(schema: Schema) {
        schema.create(table: "likes") {
            $0.string("id").primary()
            $0.string("comment_id").references("id", on: "comments").notNull()
            $0.string("user_id").references("id", on: "users").notNull()
        }
    }

    func down(schema: Schema) {
        schema.drop(table: "likes")
    }
}
