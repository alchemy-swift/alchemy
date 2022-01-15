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
        config.databases.forEach { id, db in
            db.migrations = config.migrations
            db.seeders = config.seeders
            Database.bind(id, db)
        }
        
        config.redis.forEach { RedisClient.bind($0, $1) }
    }
}
