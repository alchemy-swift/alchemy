import Alchemy

extension Application {
    /// Starts the application in a background task.
    public func background(_ args: String...) {
        background(args)
    }

    /// Starts the application in a background task.
    public func background(_ args: [String]) {
        Task { try await run(args) }
    }
}
