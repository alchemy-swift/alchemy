extension Database {
    public struct Config {
        public let databases: [Identifier: Database]
        public let migrations: [Migration]
        public let seeders: [Seeder]
        public let redis: [Redis.Identifier: Redis]
        
        public init(databases: [Database.Identifier : Database], migrations: [Migration], seeders: [Seeder], redis: [Redis.Identifier : Redis]) {
            self.databases = databases
            self.migrations = migrations
            self.seeders = seeders
            self.redis = redis
        }
    }

    public static func configure(using config: Config) {
        config.databases.forEach { id, db in
            db.migrations = config.migrations
            db.seeders = config.seeders
            Database.register(id, db)
        }
        
        config.redis.forEach(Redis.register)
    }
}
