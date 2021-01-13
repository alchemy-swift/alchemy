import NIO

/// An abstract block of work to be run.
public protocol Job {
    /// The function that should be called when it's time for this
    /// `Job` to run.
    func run() -> EventLoopFuture<Void>
}
