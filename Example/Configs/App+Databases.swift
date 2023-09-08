import Alchemy

extension App {

    /// Configurations related to your app's databases.

    var databases: Databases {
        Databases(

            /// Your default Database

            default: .sqlite,

            /// Define your databases here

            databases: [
                .postgres: .postgres(
                    host: Env.DB_HOST ?? "localhost",
                    port: Env.DB_PORT ?? 5432,
                    database: Env.DB ?? "alchemy",
                    username: Env.DB_USER ?? "josh",
                    password: Env.DB_PASSWORD ?? "password",
                    enableSSL: Env.DB_ENABLE_SSL ?? false
                ),
                .sqlite: .sqlite(path: "../test.db").logRawSQL(),
            ],

            /// Migrations for your app

            migrations: [
                Cache.AddCacheMigration(),
                Queue.AddJobsMigration(),
                AddStuffMigration(),
                AddStuff2Migration(),
                AddStuff3Migration(),
            ],

            /// Seeders for your database

            seeders: [],

            /// Your default Redis

            defaultRedis: "redis",

            /// Any redis connections can be defined here

            redis: [
                "redis": .connection(
                    Env.REDIS_HOST ?? "localhost",
                    port: Env.REDIS_PORT ?? 6379
                ),
            ]
        )
    }
}

extension Database.Identifier {
    static let sqlite: Database.Identifier = "sqlite"
    static let postgres: Database.Identifier = "postgres"
}
