import NIO

/// A utility for running expensive CPU work on threads so as not to block the current `EventLoop`.
public struct Thread {
    /// The thread pool for running expensive work on. By default, this pool has a number of threads
    /// equal to the number of logical cores on this machine.
    private static let pool = NIOThreadPool(numberOfThreads: System.coreCount)
    
    /// Runs an expensive bit of work on a thread outside of the current `EventLoop`.
    ///
    /// - Parameter task: the work to run.
    /// - Returns: a future containing the result of the expensive work that completes on the
    ///            current `EventLoop`.
    public static func run<T>(_ task: @escaping () -> T) -> EventLoopFuture<T> {
        // Start the pool only when first used. This way there's no excess threads for users that
        // don't use them.
        self.pool.start()
        return self.pool.runIfActive(eventLoop: Loop.current, task)
    }
    
    /// Attempts to shut down the backing `NIOThreadPool` synchronously.
    ///
    /// - Throws: any error encountered while shutting down the pool.
    public static func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }
}
