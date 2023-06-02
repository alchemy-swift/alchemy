extension Array {
    /// Allows for safe array lookup, returning nil of the index is
    /// out of bounds.
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}

extension Array where Element: Hashable {
    func uniques() -> Self {
        Array(Set(self))
    }
}

extension Sequence {
    public func keyed<T: Hashable>(by value: (Element) -> T) -> [T: Element] {
        let withKeys = map { (value($0), $0) }
        return Dictionary(withKeys, uniquingKeysWith: { first, _ in first })
    }

    public func grouped<T: Hashable>(by grouping: (Element) throws -> T) rethrows -> [T: [Element]] {
        try Dictionary(grouping: self, by: { try grouping($0) })
    }

    public func compactGrouped<T: Hashable>(by grouping: (Element) throws -> T?) rethrows -> [T: [Element]] {
        let tuples: [(T, Element)] = try compactMap { value in
            guard let key = try grouping(value) else {
                return nil
            }

            return (key, value)
        }

        return Dictionary(grouping: tuples, by: { $0.0 }).mapValues { $0.map(\.1) }
    }
}
