import Alchemy

struct TodoController: Controller {
    struct TodoDTO: Codable {
        let name: String
        let tagIDs: [Int]
    }
    
    func route(_ router: Router) {
        router
            // Get all todos
            .on(.GET, at: "/todos") { req -> EventLoopFuture<[Todo]> in
                let userID = try req.get(User.self).id
                return Todo.query()
                    .where("user_id" == userID)
                    .getAll()
            }
            // Create a todo, with tags
            .on(.POST, at: "/todos") { req -> EventLoopFuture<Todo> in
                let user = try req.get(User.self)
                let dto: TodoDTO = try req.getBody(encoding: .json)
                return Todo(name: dto.name, isComplete: false, user: .init(user))
                    .save()
                    .flatMap { todo in
                        Tag.query()
                            .where(key: "id", in: dto.tagIDs)
                            .getAll()
                            .mapEach { TodoTag(todo: .init(todo), tag: .init($0)) }
                            .flatMap { $0.insert() }
                            .map { _ in todo }
                    }
            }
            // Delete a todo
            .on(.DELETE, at: "/todos/:todoID") { request -> EventLoopFuture<Void> in
                let userID = try request.get(User.self).getID()
                let todoID = try request.getPathComponent(for: "todoID")
                    .unwrap(or: HTTPError(.badRequest))
                return Todo.query()
                    .where("id" == Int(todoID))
                    .where("user_id" == userID)
                    .getFirst()
                    .unwrap(orError: HTTPError(.notFound))
                    .flatMap { $0.delete() }
            }
    }
}
