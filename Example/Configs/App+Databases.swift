import Alchemy

extension Plugin where Self == Databases {
    static var databases: Databases {
        return Databases(

            /// Define your databases here

            databases: [
                .default: .postgres(
                    host: Env.DB_HOST ?? "localhost",
                    port: Env.DB_PORT ?? 5432,
                    database: Env.DB ?? "alchemy",
                    username: Env.DB_USER ?? "josh",
                    password: Env.DB_PASSWORD ?? "password",
                    enableSSL: Env.DB_ENABLE_SSL ?? false
                ).log(),
                "sqlite": .sqlite(path: "../test.db"),
            ],

            /// Migrations for your app

            migrations: [
                Cache.AddCacheMigration(),
                Queue.AddJobsMigration(),
                AddMessagesMigration(),
                AddStuffMigration(),
                AddStuff2Migration(),
                AddStuff3Migration(),
            ],

            /// Seeders for your database

            seeders: [],

            /// Any redis connections can be defined here

            redis: [
                .default: .connection(
                    Env.REDIS_HOST ?? "localhost",
                    port: Env.REDIS_PORT ?? 6379
                ),
            ]
        )
    }
}