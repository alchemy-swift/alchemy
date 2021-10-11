public final class StubDatabase: DatabaseDriver {
    private var isShutdown = false
    private var stubs: [[DatabaseRow]] = []
    
    public let grammar = Grammar()
    
    init() {}
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue]) async throws -> [DatabaseRow] {
        guard !isShutdown else {
            throw MockDatabaseError(message: "This database has been shutdown.")
        }
        
        guard let mockedRows = stubs.first else {
            throw MockDatabaseError(message: "Before running a query on a MockDatabase, please mock it with `mockQuery()`.")
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
        try data[column].unwrap(or: MockDatabaseError(message: "Mocked database row had no column `\(column)`."))
    }
}

struct MockDatabaseError: Error {
    let message: String
}
