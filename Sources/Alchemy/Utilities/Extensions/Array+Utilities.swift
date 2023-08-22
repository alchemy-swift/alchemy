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
        Dictionary(map { (value($0), $0) })
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

    func sorted<T: Comparable>(by field: (Element) -> T, order: SortOrder = .ascending) -> [Element] {
        sorted(by: {
            switch order {
            case .ascending:
                return field($0) < field($1)
            case .descending:
                return field($0) > field($1)
            }
        })
    }

    func sorted<T: Comparable>(by field: (Element) -> T?, order: SortOrder = .ascending) -> [Element] {
        sorted(by: {
            switch order {
            case .ascending:
                if let first = field($0), let second = field($1) {
                    return first < second
                } else if field($0) != nil {
                    return true
                } else if field($1) != nil {
                    return false
                } else {
                    return true
                }
            case .descending:
                if let first = field($0), let second = field($1) {
                    return first > second
                } else if field($0) != nil {
                    return false
                } else if field($1) != nil {
                    return true
                } else {
                    return false
                }
            }
        })
    }

    public var array: [Element] {
        map { $0 }
    }
}

enum SortOrder {
    case ascending, descending
}
