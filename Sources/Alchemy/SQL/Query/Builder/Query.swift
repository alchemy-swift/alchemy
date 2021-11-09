import Foundation
import NIO

public class Query {
    let database: DatabaseDriver
    
    var columns: [String] = ["*"]
    var joins: [Join] = []
    var wheres: [Where] = []
    var groups: [String] = []
    var havings: [Where] = []
    var orders: [Order] = []
    
    var from: String
    var limit: Int? = nil
    var offset: Int? = nil
    var isDistinct = false
    var lock: String? = nil

    public init(database: DatabaseDriver, from: String) {
        self.database = database
        self.from = from
    }

    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func select(_ columns: [String] = ["*"]) -> Self {
        self.columns = columns
        return self
    }

    /// Set query to only return distinct entries.
    ///
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func distinct() -> Self {
        self.isDistinct = true
        return self
    }

    /// Offset the returned results by a given amount.
    ///
    /// - Parameter value: An amount representing the offset.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func offset(_ value: Int) -> Self {
        self.offset = max(0, value)
        return self
    }

    /// Limit the returned results to a given amount.
    ///
    /// - Parameter value: An amount to cap the total result at.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func limit(_ value: Int) -> Self {
        if (value >= 0) {
            self.limit = value
        } else {
            fatalError("No negative limits allowed!")
        }
        return self
    }

    /// A helper method to be used when needing to page returned
    /// results. Internally this uses the `limit` and `offset`
    /// methods.
    ///
    /// - Note: Paging starts at index 1, not 0.
    ///
    /// - Parameters:
    ///   - page: What `page` of results to offset by.
    ///   - perPage: How many results to show on each page. Defaults
    ///     to `25`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func forPage(_ page: Int, perPage: Int = 25) -> Self {
        offset((page - 1) * perPage).limit(perPage)
    }
}
