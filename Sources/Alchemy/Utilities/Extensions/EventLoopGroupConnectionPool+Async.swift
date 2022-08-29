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
}
