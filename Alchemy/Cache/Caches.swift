public struct Caches: Plugin {
    public let `default`: Cache.Identifier?
    public let caches: () -> [Cache.Identifier: Cache]

    public init(`default`: Cache.Identifier? = nil, caches: @escaping @autoclosure () -> [Cache.Identifier: Cache] = [:]) {
        self.default = `default`
        self.caches = caches
    }

    public func boot(app: Application) {
        let caches = caches()
        for (id, cache) in caches {
            app.container.register(cache, id: id).singleton()
        }

        if let _default = `default` ?? caches.keys.first {
            app.container.register(Stash(_default)).singleton()
        }
    }
}
