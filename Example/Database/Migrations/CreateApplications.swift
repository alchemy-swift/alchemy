import Alchemy

struct CreateApplications: Migration {
    func up(schema: Schema) {
        schema.create(table: "applications") {
            $0.increments("id")
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "applications")
    }
}