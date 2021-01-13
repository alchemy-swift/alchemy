import NIO

/// Run migrations on `Services.db`, optionally rolling back the
/// latest batch.
struct MigrateRunner: Runner {
    /// Indicates whether migrations should be run (`false`) or rolled
    /// back (`true`).
    let rollback: Bool
    
    // MARK: Runner
    
    func start() -> EventLoopFuture<Void> {
        Services.eventLoopGroup
            .next()
            .flatSubmit(self.rollback ? Services.db.rollbackMigrations : Services.db.migrate)
    }
    
    func shutdown() -> EventLoopFuture<Void> {
        .new()
    }
}
