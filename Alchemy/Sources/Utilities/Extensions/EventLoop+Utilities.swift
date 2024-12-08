import NIO

extension EventLoop {
    func asyncSubmit<T>(_ action: @escaping () async throws -> T) -> EventLoopFuture<T> {
        let elp = makePromise(of: T.self)
        elp.completeWithTask { try await action() }
        return elp.futureResult
    }
}
