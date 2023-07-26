public struct SQLField: Equatable {
    public let column: String
    public let value: SQLValue

    public init(column: String, value: SQLValue) {
        self.column = column
        self.value = value
    }
}
