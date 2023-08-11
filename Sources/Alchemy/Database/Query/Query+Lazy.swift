import Foundation

extension Query {
    public func lazy(_ chunkSize: Int = 100) -> LazyQuerySequence<Result> {
        LazyQuerySequence(query: self, chunkSize: chunkSize)
    }
}

public struct LazyQuerySequence<Result: QueryResult>: AsyncSequence {
    public typealias Element = Result
    public struct Iterator: AsyncIteratorProtocol {
        let query: Query<Result>
        let chunkSize: Int
        var didFinishLoading: Bool = false
        var page: Int = 0
        var index: Int = 0
        var results: [Result]? = nil

        public mutating func next() async throws -> Result? {
            guard let results else {
                return try await loadNextPage()
            }

            guard let result = results[safe: index] else {
                guard !didFinishLoading else {
                    return nil
                }
                
                return try await loadNextPage()
            }

            index += 1
            return result
        }

        private mutating func loadNextPage() async throws -> Result? {
            let nextResults = try await query.log().page(page, pageSize: chunkSize).get()
            self.results = nextResults
            page += 1
            index = 1
            didFinishLoading = nextResults.count < chunkSize
            return nextResults.first
        }
    }

    let query: Query<Result>
    let chunkSize: Int

    public func makeAsyncIterator() -> Iterator {
        Iterator(query: query, chunkSize: chunkSize)
    }
}
