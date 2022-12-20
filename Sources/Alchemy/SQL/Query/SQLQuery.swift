import Foundation
import NIO

public class SQLQuery: Equatable {
    let db: Database
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

    public init(db: Database, table: String) {
        self.db = db
        self.table = table
    }
    
    /// Indicates the entire query should be logged when it's executed. Logs
    /// will occur at the `info` log level.
    public func log() -> Self {
        self.shouldLog = true
        return self
    }

    // MARK: Equatable

    public static func == (lhs: SQLQuery, rhs: SQLQuery) -> Bool {
        lhs.isEqual(to: rhs)
    }

    func isEqual(to other: SQLQuery) -> Bool {
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
