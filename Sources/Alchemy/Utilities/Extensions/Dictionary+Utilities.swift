extension Dictionary {
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.merging(rhs, uniquingKeysWith: { _, b in b })
    }

    init(_ keysAndValues: [(Key, Value)]) {
        self.init(keysAndValues, uniquingKeysWith: { _, b in b })
    }

    func mapKeys<H: Hashable>(_ transform: (Key) -> H) -> [H: Value]{
        [H: Value](uniqueKeysWithValues: map { (transform($0), $1) })
    }
}
