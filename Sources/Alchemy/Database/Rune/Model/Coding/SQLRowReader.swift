public protocol SQLRowReader {
    var row: SQLRow { get }
    func require(_ key: String) throws -> SQLValue
    func requireJSON<D: Decodable>(_ key: String) throws -> D
    func contains(_ column: String) -> Bool
    subscript(_ index: Int) -> SQLValue { get }
    subscript(_ column: String) -> SQLValue? { get }
}
