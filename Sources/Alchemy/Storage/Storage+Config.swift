extension Storage {
    public struct Config {
        public let stores: [Identifier: Storage]
        
        public init(stores: [Identifier : Storage]) {
            self.stores = stores
        }
    }

    public static func configure(using config: Config) {
        config.stores.forEach(Storage.register)
    }
}
