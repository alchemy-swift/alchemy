import NIO

/// Convenient extensions for working with `EventLoopFuture`s.
extension EventLoopFuture {
    /// Erases the type of the future to `Void`
    ///
    /// - Returns: an erased future of type `EventLoopFuture<Void>`.
    public func voided() -> EventLoopFuture<Void> {
        self.map { _ in () }
    }
    
    /// Creates a new errored `EventLoopFuture` on the current `EventLoop`.
    ///
    /// - Parameter error: the error to create the future with.
    /// - Returns: a created future that will resolve to an error.
    public static func new<T>(error: Error) -> EventLoopFuture<T> {
        Services.eventLoop.future(error: error)
    }
    
    /// Creates a new successed `EventLoopFuture` on the current `EventLoop`.
    ///
    /// - Parameter value: the value to create the future with.
    /// - Returns: a created future that will resolve to the provided value.
    public static func new<T>(_ value: T) -> EventLoopFuture<T> {
        Services.eventLoop.future(value)
    }
}

/// Takes a throwing block & returns either the `EventLoopFuture<T>` that block creates or an errored
/// `EventLoopFuture<T>` if the closure threw an error.
///
/// - Parameter closure: the throwing closure used to generate an `EventLoopFuture<T>`.
/// - Returns: a future with the given closure run with any errors piped into the future.
func catchError<T>(
    _ closure: () throws -> EventLoopFuture<T>
) -> EventLoopFuture<T> {
    do {
        return try closure()
    }
    catch {
        return .new(error: error)
    }
}
