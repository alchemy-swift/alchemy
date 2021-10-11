import ArgumentParser
import Lifecycle

/// Seed the database.
struct SeedDatabase: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "db:seed")
    }
    
    static var logStartAndFinish: Bool = false
    
    /// Whether specific seeders to run. If this is empty, all seeders
    /// on the database will be run.
    @Argument(help: "The specific seeders to run. If empty, all seeders will be run.")
    var name: [String] = []
    
    /// Whether specific seeders to run. If this is empty, all seeders
    /// on the database will be run.
    @Option(help: "The database to run the seeders on. Leave empty to run on the default database.")
    var database: String = ""
    
    // MARK: Command
    
    func start() async throws {
        let db: Database = database.isEmpty ? .default : .named(database)
        if name.isEmpty {
            try await db.seed()
        } else {
            try await db.seed(using: name)
        }
    }
    
    func shutdown() async throws {
        Log.info("[Seed] database seeding complete.")
    }
}
