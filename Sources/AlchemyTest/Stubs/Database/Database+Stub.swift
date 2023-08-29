extension Database {
    /// Mock the database with a database for stubbing specific queries.
    ///
    /// - Parameter id: The identifier of the database to stub, defaults to
    ///   `default`.
    @discardableResult
    public static func stub(_ id: Identifier? = nil) -> StubDatabase {
        let stub = StubDatabase()
        Container.register(Database(provider: stub, grammar: StubGrammar()), id: id).singleton()
        return stub
    }
}
