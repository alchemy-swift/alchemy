extension Store {
    public struct Config {
        public let caches: [Identifier: Store]
        
        public init(caches: [Store.Identifier : Store]) {
            self.caches = caches
        }
    }

    public static func configure(using config: Config) {
        config.caches.forEach(Store.register)
    }
}
