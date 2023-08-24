import NIO

extension NIOThreadPool {
    /// Runs an expensive bit of work on a thread that isn't backing
    /// an `EventLoop`, returning any value generated by that work
    /// back on the current `EventLoop`.
    ///
    /// - Parameter task: The work to run.
    /// - Returns: The result of the expensive work that completes on
    ///   the current `EventLoop`.
    public func run<T>(_ task: @Sendable @escaping () throws -> T) async throws -> T {
        try await runIfActive(eventLoop: Loop, task).get()
    }
}