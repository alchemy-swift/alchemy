public struct Databases: Plugin {
    private let databases: [Database.Identifier: Database]
    private let migrations: [Migration]
    private let seeders: [Seeder]
    private let redis: [RedisClient.Identifier: RedisClient]

    public init(
        databases: [Database.Identifier: Database],
        migrations: [Migration],
        seeders: [Seeder],
        redis: [RedisClient.Identifier: RedisClient]
    ) {
        self.databases = databases
        self.migrations = migrations
        self.seeders = seeders
        self.redis = redis
    }

    public func registerServices(in container: Container) {
        for (id, db) in databases {
            db.migrations = migrations
            db.seeders = seeders
            container.registerSingleton(db, id: id)
        }

        for (id, db) in redis {
            container.registerSingleton(db, id: id)
        }
    }

    public func boot(app: Application) {
        app.registerCommand(SeedCommand.self)
        app.registerCommand(MigrateCommand.self)
        app.registerCommand(RollbackMigrationsCommand.self)
        app.registerCommand(ResetMigrationsCommand.self)
        app.registerCommand(RefreshMigrationsCommand.self)
    }

    public func shutdownServices(in container: Container) async throws {
        for id in databases.keys {
            try await container.resolve(Database.self, identifier: id)?.shutdown()
        }

        for id in redis.keys {
            try await container.resolve(RedisClient.self, identifier: id)?.shutdown()
        }
    }
}
