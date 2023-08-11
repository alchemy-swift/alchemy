extension Query: AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        let query: Query<Result>
        var index: Int = 0
        var results: [Result]? = nil

        public mutating func next() async throws -> Result? {
            guard let results else {
                results = try await query.log().get()
                return try await next()
            }

            guard let result = results[safe: index] else {
                return nil
            }

            index += 1
            return result
        }
    }

    public typealias Element = Result

    public func makeAsyncIterator() -> Iterator {
        Iterator(query: self)
    }
}
