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
}
