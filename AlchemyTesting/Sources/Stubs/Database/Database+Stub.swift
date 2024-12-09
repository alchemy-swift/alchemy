extension Database {
    /// Mock this database with a database for stubbing specific queries.
    @discardableResult
    public func stub() -> StubDatabase {
        let stub = StubDatabase()
        self.provider = stub
        self.grammar = StubGrammar()
        return stub
    }
}
