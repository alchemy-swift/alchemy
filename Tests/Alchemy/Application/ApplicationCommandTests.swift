@testable
import Alchemy
import AlchemyTest

final class AlchemyCommandTests: TestCase<CommandApp> {
    func testCommandRegistration() throws {
        try app.start()
        XCTAssertTrue(Launch.customCommands.contains {
            id(of: $0) == id(of: TestCommand.self)
        })
    }
}

struct CommandApp: Application {
    var commands: [Command.Type] = [TestCommand.self]
    func boot() throws {}
}

private struct TestCommand: Command {
    static var configuration = CommandConfiguration(commandName: "command:test")
    
    func start() async throws {}
}
