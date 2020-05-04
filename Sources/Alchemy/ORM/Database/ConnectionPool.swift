import PostgresKit

// Vapor's `AsyncKit` has `EventLoopGroupConnectionPool` with a generic param. When we do our own we won't
// have that. For now leaving as `EventLoopGroupConnectionPool<PostgresConnectionSource>`.
public typealias ConnectionPool = EventLoopGroupConnectionPool<PostgresConnectionSource>
