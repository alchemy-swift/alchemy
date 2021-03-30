/// The migration table to store migrations in.
private let kMigrationTable = "migrations"

/// A migration for adding the `AlchemyMigration` table.
struct AddAlchemyMigration: Migration {
    func up(schema: Schema) {
        schema.create(table: kMigrationTable, ifNotExists: true) {
            $0.increments("id").primary()
            $0.string("name").notNull()
            $0.int("batch").notNull()
            $0.date("run_at").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: kMigrationTable)
    }
}

/// Represents a table for storing migration data. Alchemy will use
/// this table for keeping track of the various batches of
/// migrations that have been run.
struct AlchemyMigration: Model {
    // MARK: Model
    
    static var tableName: String = kMigrationTable
    
    /// Serial primary key.
    var id: Int?
    
    /// The name of the migration.
    let name: String
    
    /// The batch this migration was run as a part of.
    let batch: Int
    
    /// The timestamp when this migration was run.
    let runAt: Date?
}
