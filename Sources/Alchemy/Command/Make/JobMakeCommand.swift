import ArgumentParser

struct JobMakeCommand: Command {
    static var configuration = CommandConfiguration(
        commandName: "make:job",
        discussion: "Create a new job type"
    )
    
    @Argument var name: String
    
    init() {}
    init(name: String) {
        self.name = name
    }
    
    func start() throws {
        try FileCreator.shared.create(fileName: name, contents: jobTemplate(), in: "Jobs")
    }
    
    private func jobTemplate() -> String {
        return """
        import Alchemy
        
        struct \(name): Job {
            func run() async throws {
                // Write some code!
            }
        }
        """
    }
}
