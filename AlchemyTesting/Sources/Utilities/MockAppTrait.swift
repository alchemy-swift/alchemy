public struct MockAppTrait<A: Application>: TestTrait, SuiteTrait, TestScoping {
    public var isRecursive: Bool { true }

    public init() {}

    public func provideScope(for test: Test,
                             testCase: Test.Case?,
                             performing function: () async throws -> Void) async throws {
        let container = Container()
        try await Container.$main.withValue(container) {
            let app = A()
            try await app.willTest()
            try await function()
            try await app.didTest()
        }
    }
}
