extension Database {
    public struct Config {
        public let databases: [Identifier: Database]
        public let migrations: [Migration]
        public let seeders: [Seeder]
        public let redis: [RedisClient.Identifier: RedisClient]
        
        public init(databases: [Database.Identifier: Database], migrations: [Migration], seeders: [Seeder], redis: [RedisClient.Identifier: RedisClient]) {
            self.databases = databases
            self.migrations = migrations
            self.seeders = seeders
            self.redis = redis
        }
    }

    public static func configure(with config: Config) {
        for (id, db) in config.databases {
            db.migrations = config.migrations
            db.seeders = config.seeders
            Database.bind(id, db)
        }

        for (id, db) in config.redis {
            RedisClient.bind(id, db)
        }
    }
}
