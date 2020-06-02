import NIO

extension EventLoopFuture {
    /// NIO doesn't have a way to `flatMap` with a closure that throws. This is that.
    func throwingFlatMap<Result>(_ closure: @escaping (Value) throws -> EventLoopFuture<Result>)
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

    func voided() -> EventLoopFuture<Void> {
        self.map { _ in () }
    }
}

/// Takes a throwing block & returns either the `EventLoopFuture<T>` that block creates or an errored
/// `EventLoopFuture<T>` if the closure threw an error.
func catchError<T>(on loop: EventLoop, _ closure: () throws -> EventLoopFuture<T>)
    -> EventLoopFuture<T>
{
    do {
        return try closure()
    }
    catch {
        return loop.future(error: error)
    }
}
