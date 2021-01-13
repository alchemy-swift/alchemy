import NIO

/// An abstraction of an Alchemy program to run.
protocol Runner {
    /// Start running.
    ///
    /// - Returns: A future indicating that running has finished.
    func start() -> EventLoopFuture<Void>
    
    /// Stop running, if possible.
    ///
    /// - Returns: A future indicating that shut down has finished.
    func shutdown() -> EventLoopFuture<Void>
}
