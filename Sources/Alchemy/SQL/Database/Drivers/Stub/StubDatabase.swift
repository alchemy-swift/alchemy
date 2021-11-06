public final class StubDatabase: DatabaseDriver {
    private var isShutdown = false
    private var stubs: [[SQLRow]] = []
    
    public let grammar = Grammar()
    
    init() {}
    
    public func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
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

public struct StubDatabaseRow: SQLRow {
    public let data: [String: SQLValueConvertible]
    public let columns: Set<String>
    
    public init(data: [String: SQLValueConvertible] = [:]) {
        self.data = data
        self.columns = Set(data.keys)
    }
    
    public func get(_ column: String) throws -> SQLValue {
        try data[column].unwrap(or: DatabaseError("Stubbed database row had no column `\(column)`.")).value
    }
}
