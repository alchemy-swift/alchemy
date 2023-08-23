import ArgumentParser
import Lifecycle

/// Seed the database.
struct SeedCommand: Command {
    static var name = "db:seed"

    /// Whether specific seeders to run. If this is empty, all seeders
    /// on the database will be run.
    @Argument(help: "The specific seeders to run. If empty, all seeders will be run.")
    var seeders: [String] = []
    
    /// Whether specific seeders to run. If this is empty, all seeders
    /// on the database will be run.
    @Option(help: "The database to run the seeders on. Leave empty to run on the default database.")
    var db: String?
    
    init() {}
    init(db: String?, seeders: [String] = []) {
        self.db = db
        self.seeders = seeders
    }
    
    // MARK: Command
    
    func run() async throws {
        let db = Container.resolveAssert(Database.self, id: db)
        guard seeders.isEmpty else {
            try await db.seed(names: seeders)
            return
        }
        
        try await db.seed()
    }
}
