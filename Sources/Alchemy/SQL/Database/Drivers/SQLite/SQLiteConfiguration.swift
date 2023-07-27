import AsyncKit
import SQLiteNIO

public struct SQLiteConfiguration: ConnectionPoolSource {
    public enum Storage {
        /// Stores the SQLite database in memory.
        ///
        /// Uses a randomly generated identifier. See `memory(identifier:)`.
        public static var memory: Self {
            .memory(identifier: UUID().uuidString)
        }

        /// Stores the SQLite database in memory.
        /// - parameters:
        ///     - identifier: Uniquely identifies the in-memory storage.
        ///                   Connections using the same identifier share data.
        case memory(identifier: String)

        /// Uses the SQLite database file at the specified path.
        ///
        /// Non-absolute paths will check the current working directory.
        case file(path: String)
    }

    /// The thread pool on which the SQLite file will be accessed.
    public let threadPool: NIOThreadPool
    /// Where the SQLite database is stored.
    public let storage: Storage
    /// If `true`, foreign keys will be enabled automatically on new connections.
    public let enableForeignKeys: Bool

    private var connectionStorage: SQLiteConnection.Storage {
        switch storage {
        case .memory(let identifier):
            return .file(path: "file:\(identifier)?mode=memory&cache=shared")
        case .file(let path):
            return .file(path: path)
        }
    }

    public init(threadPool: NIOThreadPool = Thread.pool, storage: Storage, enableForeignKeys: Bool = true) {
        self.threadPool = threadPool
        self.storage = storage
        self.enableForeignKeys = enableForeignKeys
    }

    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<SQLiteConnection> {
        SQLiteConnection.open(storage: connectionStorage, threadPool: threadPool, logger: logger, on: eventLoop)
            .flatMap { conn in
                if enableForeignKeys {
                    return conn.query("PRAGMA foreign_keys = ON").map { _ in conn }
                } else {
                    return eventLoop.makeSucceededFuture(conn)
                }
            }
    }
}
