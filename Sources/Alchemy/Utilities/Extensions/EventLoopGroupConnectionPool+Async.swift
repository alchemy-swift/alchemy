import AsyncKit

extension EventLoopGroupConnectionPool {
    /// Async wrapper around the future variant of `withConnection`.
    public func withConnection<Result>(
        logger: Logger? = nil,
        on eventLoop: EventLoop? = nil,
        _ closure: @escaping (Source.Connection) async throws -> Result
    ) async throws -> Result {
        try await withConnection(logger: logger, on: eventLoop) { connection in
            connection.eventLoop.asyncSubmit { try await closure(connection) }
        }.get()
    }

    /// Async wrapper for `shutdownGracefully`.
    public func asyncShutdownGracefully() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            shutdownGracefully { error in
                if let error {
                    c.resume(throwing: error)
                } else {
                    c.resume()
                }
            }
        }
    }
}
