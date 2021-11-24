import AlchemyTest

final class CommandTests: TestCase<TestApp> {
    func testCommandRuns() async throws {
        struct TestCommand: Command {
            static var didRun: (() -> Void)? = nil
            
            func start() async throws {
                TestCommand.didRun?()
            }
        }
        
        let exp = expectation(description: "")
        TestCommand.didRun = {
            exp.fulfill()
        }
        
        try TestCommand().run()
        
        @Inject var lifecycle: ServiceLifecycle
        try lifecycle.startAndWait()
        
        await waitForExpectations(timeout: kMinTimeout)
    }
}
