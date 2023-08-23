public struct Caches: Plugin {
    public let `default`: Cache.Identifier?
    public let caches: [Cache.Identifier: Cache]

    public init(`default`: Cache.Identifier? = nil, caches: [Cache.Identifier: Cache] = [:]) {
        self.default = `default`
        self.caches = caches
    }

    public func registerServices(in app: Application) {
        for (id, cache) in caches {
            app.container.registerSingleton(cache, id: id)
        }

        if let _default = `default` {
            app.container.registerSingleton(Stash(_default))
        }
    }
}
