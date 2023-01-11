public protocol EagerLoadable where Self: Model {
    var cache: ModelCache? { get set }
}

extension EagerLoadable {
    mutating func cache<To: RelationAllowed>(hashValue: Int, value: To) {
        cache?.relationships[hashValue] = value
    }

    func checkCache<To: RelationAllowed>(hashValue: Int) -> To? {
        cache?.relationships[hashValue] as? To
    }

    func cacheExists(hashValue: Int) -> Bool {
        cache?.relationships[hashValue] != nil
    }
}
