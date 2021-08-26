@testable import Alchemy
import XCTest

struct App: Application {
    func boot() {}
}

final class RelationshipTests: XCTestCase {
    override class func setUp() {
        App().mockServices()
        Database.config(default: .mysql(host: "", database: "", username: "", password: ""))
    }
    
//    func testBelongsTo() {
//        let config = Todo.BelongsTo<User>.defaultConfig()
//        let query = config.load(for: [.int(0)]).toSQL()
//        print("belongs: \(query.query) \(query.bindings)")
//    }
//    
//    func testHasMany() {
//        let config = User.HasMany<Todo>.defaultConfig()
//        let query = config.load(for: [.int(0)]).toSQL()
//        print("many: \(query.query) \(query.bindings)")
//    }
//    
//    func testHasOne() {
//        let config = User.HasOne<Todo>.defaultConfig()
//        let query = config.load(for: [.int(0)]).toSQL()
//        print("one: \(query.query) \(query.bindings)")
//    }
//    
//    func testHasThrough() {
//        let mapper = RelationMapper<Todo>()
//        Todo.mapRelations(mapper)
//        let config = mapper.config(for: \Todo.$users)
//        let query = config.load(for: [.int(0)]).toSQL()
//        print("through: \(query.query) \(query.bindings)")
//    }
}

struct User: Model {
    var id: Int?
    @HasMany var todos: [Todo]
    @HasMany var todosThrough: [Todo]
    @BelongsTo var todo: Todo
    
    static func mapRelations(_ mapper: RelationshipMapper<User>) {
        mapper.relate(\.$todosThrough).through("user_todos")
    }
}

struct Todo: Model {
    var id: Int?
    @HasMany var users: [User]
    @BelongsTo var user: User
    
    static func mapRelations(_ mapper: RelationshipMapper<Todo>) {
        mapper.relate(\.$users).through("user_todos")
    }
}
