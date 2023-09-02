import Alchemy

struct CreateApplications: Migration {
    func up(db: Database) async throws {
        try await db.createTable("applications") {
            $0.increments("id")
        }
    }
    
    func down(db: Database) async throws {
        try await db.dropTable("applications")
    }
}
