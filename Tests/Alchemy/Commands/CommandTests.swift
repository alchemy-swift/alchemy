import AlchemyTest

final class CommandTests: TestCase<TestApp> {
    func testCommandRuns() async throws {
        struct TestCommand: Command {
            static var action: (() async -> Void)? = nil
            
            func start() async throws {
                await TestCommand.action?()
            }
        }
        
        let expect = Expect()
        TestCommand.action = {
            await expect.signalOne()
        }
        
        try TestCommand().run()
        
        @Inject var lifecycle: ServiceLifecycle
        try lifecycle.startAndWait()
        
        AssertTrue(await expect.one)
    }
}
