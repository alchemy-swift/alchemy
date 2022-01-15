extension Cache {
    public struct Config {
        public let caches: [Identifier: Cache]
        
        public init(caches: [Cache.Identifier : Cache]) {
            self.caches = caches
        }
    }

    public static func configure(with config: Config) {
        config.caches.forEach { Cache.bind($0, $1) }
    }
}
