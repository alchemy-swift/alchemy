import Alchemy

struct TodoController: Controller {
    /// A DTO representing the data needed to create a `Todo`.
    private struct TodoCreateDTO: Codable {
        let name: String
        let tagIDs: [Int]
    }
    
    func route(_ app: Application) {
        app
            // Get all todos.
            //
            // Note that since the Rune `Model`s conform to `Codable`,
            // we can return them directly to the client as JSON. In
            // practice, you may want separate models for returning
            // JSON to the client to keep the logic separate. For
            // this demo, we can just return the same `Model`.
            .get("/todo") { req -> EventLoopFuture<[Todo]> in
                // `TokenAuthMiddleware` sets the `User` on the
                // request making it simple to query their
                // todos.
                let userID = try req.get(User.self).getID()
                return Todo.query()
                    .where("user_id" == userID)
                    // Load tags as well to return.
                    .with(\.$tags)
                    .allModels()
            }
            // Create a todo, with tags
            .post("/todo") { req -> EventLoopFuture<Todo> in
                let user = try req.get(User.self)
                let dto: TodoCreateDTO = try req.decodeBody()
                // Create a new `Todo`...
                return Todo(name: dto.name, isComplete: false, user: .init(user))
                    // Save it...
                    .save()
                    // When that is finished...
                    .flatMap { todo in
                        // Query tags with the provided ids...
                        Tag.query()
                            .where(key: "id", in: dto.tagIDs)
                            .allModels()
                            // Create `TodoTag`s for each of them...
                            .mapEach { TodoTag(todo: .init(todo), tag: .init($0)) }
                            // Save them all...
                            .flatMap { $0.insertAll() }
                            // Return the newly created `Todo`.
                            .map { _ in todo }
                    }
            }
            // Delete a todo
            .delete("/todo/:todoID") { request -> EventLoopFuture<Void> in
                let userID = try request.get(User.self).getID()
                // Fetch the relevant path component...
                let idString = try request.pathComponent(for: "todoID")
                    .unwrap(or: HTTPError(.badRequest))
                let todoID = try Int(idString)
                    .unwrap(or: HTTPError(.badRequest))
                // Find the `Todo` with the given ID & userID (so
                // that only the owner of the `Todo` can delete
                // it).
                return Todo.query()
                    .where("id" == todoID)
                    .where("user_id" == userID)
                    .firstModel()
                    // Unwrap it, or return a 404 if it wasn't found.
                    .unwrap(orError: HTTPError(.notFound))
                    // First, delete the `TodoTag`s associated with this
                    // `Todo`
                    .flatMap { todo in
                        TodoTag
                            .query()
                            .where("todo_id" == todoID)
                            .delete()
                            // Then, delete the todo itself.
                            .flatMap { _ in todo.delete() }
                    }
            }
            // Complete a Todo
            .patch("/todo/:todoID") { request -> EventLoopFuture<Todo> in
                let userID = try request.get(User.self).getID()
                // Fetch the relevant path component...
                let idString = try request.pathComponent(for: "todoID")
                    .unwrap(or: HTTPError(.badRequest))
                let todoID = try Int(idString)
                    .unwrap(or: HTTPError(.badRequest))
                // Find the `Todo` with the given ID & userID (so that
                // only the owner of the `Todo` can complete it).
                return Todo.query()
                    .where("id" == todoID)
                    .where("user_id" == userID)
                    .firstModel()
                    // Unwrap it, or return a 404 if it wasn't found.
                    .unwrap(orError: HTTPError(.notFound))
                    // Toggle the Todo's completion status, then save
                    // it.
                    .flatMap { todo -> EventLoopFuture<Todo> in
                        var updated = todo
                        updated.isComplete.toggle()
                        return updated.save()
                    }
            }
    }
}
