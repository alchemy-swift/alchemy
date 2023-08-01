import Alchemy

extension Plugin where Self == Databases {
    static var databases: Databases {
        let sqlite: Database = .sqlite(path: "../test.db")
        let postgres: Database = .postgres(
            host: Environment.DB_HOST ?? "localhost",
            port: Environment.DB_PORT ?? 5432,
            database: Environment.DB ?? "alchemy",
            username: Environment.DB_USER ?? "josh",
            password: Environment.DB_PASSWORD ?? "password",
            enableSSL: Environment.DB_ENABLE_SSL ?? false
        ).log()

        return Databases(

            /// Define your databases here

            databases: [
                .default: Env.isTesting ? .sqlite : sqlite,
                "sqlite": .sqlite
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
                    Environment.REDIS_HOST ?? "localhost",
                    port: Environment.REDIS_PORT ?? 6379
                ),
            ]
        )
    }
}
