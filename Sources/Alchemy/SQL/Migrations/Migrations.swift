import Fusion

public final class Migrations {
    private var migrations: [Migration] = []
    
    func add(_ migration: Migration) {
        self.migrations.append(migration)
    }
    
    func migrate() {
        // Run all migrations that haven't been run as a new batch
    }
    
    func rollback() {
        // Rollback last batch of migrations
    }
}

extension Migrations: SingletonService {
    public static func singleton(in container: Container) throws -> Migrations {
        Migrations()
    }
}
