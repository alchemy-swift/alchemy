protocol SQLDecodable {
    init(from sql: SQLValue, at column: String) throws
}
