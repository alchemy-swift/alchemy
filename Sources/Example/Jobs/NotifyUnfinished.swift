import Alchemy

struct NotifyUnfinishedTodos: Job {
    func run() -> EventLoopFuture<Void> {
        // Fetch all todos, with users.
        Todo.query()
            .with(\.$user)
            .where("is_complete" == false)
            .allModels()
            .map { _ in
                // Todo: notify users of unfinished tasks
            }
    }
}
