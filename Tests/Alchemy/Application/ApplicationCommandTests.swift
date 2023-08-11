@testable
import Alchemy
import AlchemyTest

final class ApplicationCommandTests: TestCase<CommandApp> {
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
    static var name = "command:test"
    
    func start() async throws {}
}
