import ArgumentParser

struct Migrate<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "migrate")
    }
    
    @Flag(help: "Should migrations be rolled back")
    var rollback: Bool = false
    
    func run() throws {
        try A().launch(.migrate(rollback: self.rollback))
    }
}
