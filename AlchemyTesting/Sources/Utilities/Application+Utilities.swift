import Alchemy

public extension Application {
    /// Starts the application in a background task.
    func background(_ args: String...) {
        background(args)
    }

    /// Starts the application in a background task.
    func background(_ args: [String]) {
        Task { try await run(args) }
    }

    func willTest() async throws {
        try await willRun()
    }

    func didTest() async throws {
        await stop()
        try await didRun()
        Container.reset()
    }
}
