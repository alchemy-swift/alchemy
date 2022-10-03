import Foundation
import NIO

public class Query: Equatable {
    let database: Database
    var table: String
    var shouldLog: Bool = false

    var columns: [String] = ["*"]
    var isDistinct = false
    var limit: Int? = nil
    var offset: Int? = nil
    var lock: Lock? = nil
    
    var joins: [Join] = []
    var wheres: [Where] = []
    var groups: [String] = []
    var havings: [Where] = []
    var orders: [Order] = []

    public init(database: Database, table: String) {
        self.database = database
        self.table = table
    }
    
    /// Indicates the entire query should be logged when it's executed. Logs
    /// will occur at the `debug` log level.
    public func debug() -> Self {
        self.shouldLog = true
        return self
    }

    // MARK: Equatable

    public static func == (lhs: Query, rhs: Query) -> Bool {
        lhs.isEqual(to: rhs)
    }

    func isEqual(to other: Query) -> Bool {
        return table == other.table &&
            columns == other.columns &&
            isDistinct == other.isDistinct &&
            limit == other.limit &&
            offset == other.offset &&
            lock == other.lock &&
            joins == other.joins &&
            wheres == other.wheres &&
            groups == other.groups &&
            havings == other.havings &&
            orders == other.orders
    }
}
