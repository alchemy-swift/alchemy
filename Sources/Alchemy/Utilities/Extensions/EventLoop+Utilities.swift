import NIO

extension EventLoop {
    func wrapAsync<T>(_ action: @escaping () async throws -> T) -> EventLoopFuture<T> {
        let elp = makePromise(of: T.self)
        elp.completeWithTask { try await action() }
        return elp.futureResult
    }
}
