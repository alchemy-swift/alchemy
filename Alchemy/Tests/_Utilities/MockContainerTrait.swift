import AlchemyTesting

struct MockContainerTrait: TestTrait, SuiteTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(for test: Test,
                      testCase: Test.Case?,
                      performing function: () async throws -> Void) async throws {
        let container = Container()
        try await Container.$main.withValue(container) {
            let app = TestApp()
            try await app.willTest()
            try await function()
            try await app.didTest()
        }
    }
}

extension Trait where Self == MockContainerTrait {
    static var mockContainer: Self { Self() }
}
