struct Database {
    func configure() {

    }
}

extension Database: Injectable {
    static func create(_ isMock: Bool) -> Database {
        Database()
    }
}

extension Database {
    func add(table: Table) {

    }

    func migrate(table: Table, migration: () -> Void) {

    }
}

struct SampleSetup {
    @Inject var db: Database

    func setup() {
        // Regular model tables
        self.db.add(table: User.table)
        self.db.add(table: Todo.table)

        // Junction tables
        self.db.add(table: JunctionTables.passportCountries)

        // Migrations
        self.db.migrate(table: Todo.table, migration: { })
    }
}
