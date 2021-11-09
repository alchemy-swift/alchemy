extension Database {
    /// Mock the database with a database for stubbing specific queries.
    ///
    /// - Parameter name: The name of the database to stub, defaults to nil for
    ///   stubbing the default database.
    @discardableResult
    public static func stub(_ name: String? = nil) -> StubDatabase {
        let driver = StubDatabase()
        if let name = name {
            config(name, Database(driver: driver))
        } else {
            config(default: Database(driver: driver))
        }
        
        return driver
    }
}
