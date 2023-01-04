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
    func filterUniqueValues() -> Self {
        Array(Set(self))
    }
}
