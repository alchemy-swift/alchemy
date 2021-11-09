import Foundation
import NIO
import OrderedCollections

public class Query {
    let database: DatabaseDriver
    
    var columns: [SQL] = [SQL("*")]
    var joins: [JoinClause]? = nil
    var wheres: [WhereClause] = []
    var groups: [String] = []
    var havings: [WhereClause] = []
    var orders: [OrderClause] = []
    
    var from: String?
    var limit: Int? = nil
    var offset: Int? = nil
    var isDistinct = false
    var lock: String? = nil

    public init(database: DatabaseDriver) {
        self.database = database
    }

    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func select(_ columns: [Column] = ["*"]) -> Self {
        self.columns = columns.map(\.columnSQL)
        return self
    }

    /// Set the table to perform a query from.
    ///
    /// - Parameters:
    ///   - table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func table(_ table: String) -> Self {
        self.from = table
        return self
    }

    /// An alias for `table(_ table: String)` to be used when running.
    /// a `select` query that also lets you alias the table name.
    ///
    /// - Parameters:
    ///   - table: The table to select data from.
    ///   - alias: An alias to use in place of table name. Defaults to
    ///     `nil`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func from(_ table: String, as alias: String? = nil) -> Self {
        guard let alias = alias else {
            return self.table(table)
        }
        return self.table("\(table) as \(alias)")
    }

    /// Order the data from the query based on given clause.
    ///
    /// - Parameter order: The `OrderClause` that defines the
    ///   ordering.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(_ order: OrderClause) -> Self {
        self.orders.append(order)
        return self
    }

    /// Order the data from the query based on a column and direction.
    ///
    /// - Parameters:
    ///   - column: The column to order data by.
    ///   - direction: The `OrderClause.Sort` direction (either `.asc`
    ///     or `.desc`). Defaults to `.asc`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(column: Column, direction: OrderClause.Direction = .asc) -> Self {
        self.orderBy(OrderClause(column: column, direction: direction))
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
