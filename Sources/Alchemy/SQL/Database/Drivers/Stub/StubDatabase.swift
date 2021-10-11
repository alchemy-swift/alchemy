public final class StubDatabase: DatabaseDriver {
    private var isShutdown = false
    private var stubs: [[DatabaseRow]] = []
    
    public let grammar = Grammar()
    
    init() {}
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue]) async throws -> [DatabaseRow] {
        guard !isShutdown else {
            throw DatabaseError("This stubbed database has been shutdown.")
        }
        
        guard let mockedRows = stubs.first else {
            throw DatabaseError("Before running a query on a stubbed database, please stub it's resposne with `stub()`.")
        }
        
        return mockedRows
    }
    
    public func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    public func shutdown() throws {
        isShutdown = true
    }
    
    public func stub(_ rows: [StubDatabaseRow]) {
        stubs.append(rows)
    }
}

public struct StubDatabaseRow: DatabaseRow {
    public let data: [String: DatabaseField] = [:]
    public var allColumns: Set<String> { Set(data.keys) }
    
    public func getField(column: String) throws -> DatabaseField {
        try data[column].unwrap(or: DatabaseError("Stubbed database row had no column `\(column)`."))
    }
}
