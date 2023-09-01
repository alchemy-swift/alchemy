import Alchemy

public struct StubGrammar: SQLGrammar {}

public final class StubDatabase: DatabaseProvider {
    private var isShutdown = false
    private var stubs: [[SQLRow]] = []
    
    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        guard !isShutdown else {
            throw StubDatabaseError("This stubbed database has been shutdown.")
        }
        
        guard let mockedRows = stubs.first else {
            throw StubDatabaseError("Before running a query on a stubbed database, please stub it's response with `stub()`.")
        }
        
        return mockedRows
    }
    
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await query(sql, parameters: [])
    }
    
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    public func shutdown() throws {
        isShutdown = true
    }
    
    public func stub(_ rows: [SQLRow]) {
        stubs.append(rows)
    }
}

/// An error encountered when interacting with a `StubDatabase`.
public struct StubDatabaseError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `DatabaseError` with a message detailing what went wrong.
    init(_ message: String) {
        self.message = message
    }
}
