public struct Databases: Plugin {
    private let `default`: Database.Identifier?
    private let databases: [Database.Identifier: Database]
    private let migrations: [Migration]
    private let seeders: [Seeder]
    private let defaultRedis: RedisClient.Identifier?
    private let redis: [RedisClient.Identifier: RedisClient]

    public init(
        default: Database.Identifier? = nil,
        databases: [Database.Identifier: Database] = [:],
        migrations: [Migration] = [],
        seeders: [Seeder] = [],
        defaultRedis: RedisClient.Identifier? = nil,
        redis: [RedisClient.Identifier: RedisClient] = [:]
    ) {
        self.default = `default`
        self.databases = databases
        self.migrations = migrations
        self.seeders = seeders
        self.defaultRedis = defaultRedis
        self.redis = redis
    }

    public func registerServices(in app: Application) {
        for (id, db) in databases {
            db.migrations = migrations
            db.seeders = seeders
            app.container.registerSingleton(db, id: id)
        }

        if let _default = `default` {
            app.container.registerSingleton(DB(_default))
        }

        for (id, db) in redis {
            app.container.registerSingleton(db, id: id)
        }

        if let _default = defaultRedis {
            app.container.registerSingleton(Redis(_default))
        }
    }

    public func boot(app: Application) {
        app.registerCommand(SeedCommand.self)
        app.registerCommand(MigrateCommand.self)
        app.registerCommand(RollbackMigrationsCommand.self)
        app.registerCommand(ResetMigrationsCommand.self)
        app.registerCommand(RefreshMigrationsCommand.self)
    }

    public func shutdownServices(in app: Application) async throws {
        for id in databases.keys {
            try await app.container.resolve(Database.self, id: id)?.shutdown()
        }

        for id in redis.keys {
            try await app.container.resolve(RedisClient.self, id: id)?.shutdown()
        }
    }
}
