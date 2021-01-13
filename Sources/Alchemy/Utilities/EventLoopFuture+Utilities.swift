import NIO

/// Convenient extensions for working with `EventLoopFuture`s.
extension EventLoopFuture {
    /// Erases the type of the future to `Void`
    ///
    /// - Returns: An erased future of type `EventLoopFuture<Void>`.
    public func voided() -> EventLoopFuture<Void> {
        self.map { _ in () }
    }
    
    /// Creates a new errored `EventLoopFuture` on the current
    /// `EventLoop`.
    ///
    /// - Parameter error: The error to create the future with.
    /// - Returns: A created future that will resolve to an error.
    public static func new<T>(error: Error) -> EventLoopFuture<T> {
        Services.eventLoop.future(error: error)
    }
    
    /// Creates a new successed `EventLoopFuture` on the current
    /// `EventLoop`.
    ///
    /// - Parameter value: The value to create the future with.
    /// - Returns: A created future that will resolve to the provided
    ///   value.
    public static func new<T>(_ value: T) -> EventLoopFuture<T> {
        Services.eventLoop.future(value)
    }
}

extension EventLoopFuture where Value == Void {
    /// Creates a new successed `EventLoopFuture` on the current
    /// `EventLoop`.
    ///
    /// - Returns: A created future that will resolve immediately.
    public static func new() -> EventLoopFuture<Void> {
        .new(())
    }
}

/// Takes a throwing block & returns either the `EventLoopFuture<T>`
/// that block creates or an errored `EventLoopFuture<T>` if the
/// closure threw an error.
///
/// - Parameter closure: The throwing closure used to generate an
///   `EventLoopFuture<T>`.
/// - Returns: A future with the given closure run with any errors
///   piped into the future.
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
