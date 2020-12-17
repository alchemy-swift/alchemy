import NIO

extension EventLoopFuture {
    /// NIO doesn't have a way to `flatMap` with a closure that throws. This is that.
    public func throwingFlatMap<Result>(_ closure: @escaping (Value) throws -> EventLoopFuture<Result>)
        -> EventLoopFuture<Result>
    {
        self.flatMap { value in
            do {
                return try closure(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    public func voided() -> EventLoopFuture<Void> {
        self.map { _ in () }
    }
}

/// Takes a throwing block & returns either the `EventLoopFuture<T>` that block creates or an errored
/// `EventLoopFuture<T>` if the closure threw an error.
public func catchError<T>(
    _ closure: () throws -> EventLoopFuture<T>
) -> EventLoopFuture<T> {
    do {
        return try closure()
    }
    catch {
        return Loop.future(error: error)
    }
}
