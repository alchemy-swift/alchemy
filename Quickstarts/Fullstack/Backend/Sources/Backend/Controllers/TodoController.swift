import Alchemy
import Shared

struct TodoController: Controller {
    let api = TodoAPI()
    
    func route(_ app: Application) {
        app
            // Get all todos
            .on(self.api.getAll) { req in
                // `TokenAuthMiddleware` sets the `User` on the
                // request making it simple to query their
                // todos.
                let userID = try req.get(User.self).getID()
                return Todo.query()
                    .where("user_id" == userID)
                    // Eager load tags.
                    .with(\.$tags)
                    .allModels()
                    .flatMapEachThrowing { try $0.toDTO() }
            }
            // Create a todo, with tags
            .on(self.api.create, handler: { req, content in
                self.createTodo(req: req, content: content)
            })
            // Delete a todo
            .on(self.api.delete) { req, content in
                try self.deleteTodo(req: req, content: content)
            }
    }
    
    func createTodo(req: Request, content: TodoAPI.CreateTodoRequest) throws -> EventLoopFuture<TodoAPI.TodoDTO> {
        let user = try req.get(User.self)
        // Create a new `Todo`...
        return Todo(name: content.dto.name, isComplete: false, user: .init(user))
            // Save it...
            .save()
            // When that is finished...
            .flatMap { todo in
                // Query tags with the provided ids...
                Tag.query()
                    .where(key: "id", in: content.dto.tagIDs)
                    .allModels()
                    // Create `TodoTag`s for each of them...
                    .mapEach { TodoTag(todo: .init(todo), tag: .init($0)) }
                    // Save them all...
                    .flatMap { $0.insertAll() }
                    // Return the newly created `Todo`.
                    .map { _ in todo }
            }
            .flatMapThrowing { try $0.toDTO() }
    }
    
    func deleteTodo(req: Request, content: TodoAPI.DeleteTodoRequest) throws -> EventLoopFuture<Void> {
        let userID = try req.get(User.self).getID()
        // Fetch the relevant path component...
        let todoID = try Int(content.todoID)
            .unwrap(or: HTTPError(.badRequest))
        // Find the `Todo` with the given ID & userID (so
        // that only the owner of the `Todo` can delete
        // it).
        return Todo.query()
            .where("id" == Int(todoID))
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
}

extension Todo {
    // Convert this `Todo` to the `TodoDTO` expected by `TodoAPI`.
    func toDTO() throws -> TodoAPI.TodoDTO {
        TodoAPI.TodoDTO(
            id: try self.getID(),
            name: self.name,
            isComplete: self.isComplete,
            tags: try self.tags.map { try $0.toDTO() }
        )
    }
}
