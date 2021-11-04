@testable
import Alchemy
import AlchemyTest

final class AlchemyCommandTests: TestCase<TestApp> {
    func testCommandRegistration() {
        app.registerCommand(TestCommand.self)
        XCTAssertTrue(app.customCommands.contains(where: {
            id(of: $0) == id(of: TestCommand.self)
        }))
    }
}

private struct TestCommand: Command {
    static var configuration = CommandConfiguration(commandName: "command:test")
    
    func start() async throws {}
}
