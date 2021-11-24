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
    var seeders: [String] = []
    
    /// Whether specific seeders to run. If this is empty, all seeders
    /// on the database will be run.
    @Option(help: "The database to run the seeders on. Leave empty to run on the default database.")
    var database: String?
    
    init() {}
    init(database: String?, seeders: [String] = []) {
        self.database = database
        self.seeders = seeders
    }
    
    // MARK: Command
    
    func start() async throws {
        let db: Database = database.map { .resolve(.init($0)) } ?? .default
        guard seeders.isEmpty else {
            try await db.seed(names: seeders)
            return
        }
        
        try await db.seed()
    }
    
    func shutdown() async throws {
        Log.info("[Seed] database seeding complete.")
    }
}
