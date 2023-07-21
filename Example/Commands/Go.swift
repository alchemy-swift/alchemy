import Alchemy

struct Go: Command {
    static var _commandName: String = "go"

    func start() async throws {
        let user = try await User.query()
//            .with(\.posts)
//            .with(\.tokens)
            .where("id" == "user_1")
            .first()!
//        print("USER: \(user.name)")
//        let posts = try await user.posts()
//        print("POSTS: \(posts.map(\.id))")
//        let tokens = try await user.tokens()
//        print("TOKENS: \(tokens.map(\.id))")
//        let throughTokens = try await posts.first!.tokens()
//        print("THROUGH TOKENS: \(throughTokens.map(\.id))")
//        let comments = try await user.comments()
//        let owner = try await comments.first!.postOwner()
//        let friends = try await user.friends()

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

/*
 DONE:
 1. Basic relationships & through relationships

 LEFT:
 1. KeyPath loading `with`.
 2. Load in between relationships.
 3. Don't let where permanently change the query.
 4. Support wheres on relationships.
 */

struct User: Model {
    var id: PK<String> = .new
    let name: String
    let age: Int

    var tokens: Relationship<[UserToken]> {
        hasMany()
    }

    var posts: Relationship<[Post]> {
        hasMany()
    }

    var comments: Relationship<[Comment]> {
        hasMany().through("posts")
    }

    var friends: Relationship<[User]> {
        hasMany().throughPivot("friends", from: "user_a", to: "user_b")
    }
}

struct UserToken: Model {
    var id: PK<String> = .new
    let token: String
    let userId: String

    var user: Relationship<User> {
        belongsTo()
    }
}

struct Post: Model {
    var id: PK<String> = .new
    let title: String
    let userId: String

    var tokens: Relationship<[UserToken]> {
        hasMany(from: "user_id")
            .through("users", from: "id")
    }
}

struct Comment: Model {
    var id: PK<String> = .new
    let text: String
    let userId: String

    var postOwner: Relationship<User> {
        belongsTo().through(Post.self)
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