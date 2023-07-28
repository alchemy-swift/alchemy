import Alchemy

struct CreateApplications: Migration {
    func up(db: Database) async throws {
        try await db.create(table: "applications") {
            $0.increments("id")
        }
    }
    
    func down(db: Database) async throws {
        try await db.drop(table: "applications")
    }
}
