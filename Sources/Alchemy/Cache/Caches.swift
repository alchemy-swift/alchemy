public struct Caches: Plugin {
    public let caches: [Cache.Identifier: Cache]

    public init(caches: [Cache.Identifier: Cache]) {
        self.caches = caches
    }

    public func registerServices(in container: Container) {
        for (id, cache) in caches {
            container.registerSingleton(cache, id: id)
        }
    }
}
