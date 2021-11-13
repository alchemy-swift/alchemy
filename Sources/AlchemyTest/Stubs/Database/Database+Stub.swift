extension Database {
    /// Mock the database with a database for stubbing specific queries.
    ///
    /// - Parameter id: The identifier of the database to stub, defaults to
    ///   `default`.
    @discardableResult
    public static func stub(_ id: Identifier = .default) -> StubDatabase {
        let stub = StubDatabase()
        register(id, Database(driver: stub))
        return stub
    }
}
