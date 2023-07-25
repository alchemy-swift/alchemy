extension Dictionary {
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.merging(rhs, uniquingKeysWith: { a, _ in a })
    }

    init(_ keysAndValues: [(Key, Value)]) {
        self.init(keysAndValues, uniquingKeysWith: { a, _ in a })
    }
}
