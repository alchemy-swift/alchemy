import ArgumentParser

struct MakeJob: Command {
    static var logStartAndFinish: Bool = false
    static var configuration = CommandConfiguration(
        commandName: "make:job",
        discussion: "Create a new job type"
    )
    
    @Argument var name: String
    
    func start() -> EventLoopFuture<Void> {
        catchError {
            try FileCreator.shared.create(fileName: name, contents: jobTemplate(), in: "Jobs")
            return .new()
        }
    }
    
    private func jobTemplate() -> String {
        return """
        import Alchemy
        
        struct \(name): Job {
            func run() -> EventLoopFuture<Void> {
                // Write some code!
                return .new()
            }
        }
        """
    }
}
