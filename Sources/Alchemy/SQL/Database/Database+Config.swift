extension Database {
    public struct Config {
        let databases: [Identifier: Database]
        let migrations: [Migration]
        let seeders: [Seeder]
        let redis: [Redis.Identifier: Redis]
        
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
