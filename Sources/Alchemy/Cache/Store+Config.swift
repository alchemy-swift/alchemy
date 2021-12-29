extension Cache {
    public struct Config {
        public let caches: [Identifier: Cache]
        
        public init(caches: [Cache.Identifier : Cache]) {
            self.caches = caches
        }
    }

    public static func configure(using config: Config) {
        config.caches.forEach(Cache.register)
    }
}
