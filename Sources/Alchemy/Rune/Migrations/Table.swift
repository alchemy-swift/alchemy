public protocol Table {
    static var tableName: String { get }
}

extension Table {
    public static var tableName: String { String(describing: Self.self) }
}
