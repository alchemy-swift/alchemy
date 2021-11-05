import Collections

extension OrderedDictionary {
    var dictionary: [Key: Value] {
        Dictionary(uniqueKeysWithValues: map { ($0, $1) })
    }
}
