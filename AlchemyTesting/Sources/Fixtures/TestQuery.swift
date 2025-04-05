import Alchemy

public final class TestQuery: Query<SQLRow> {
    public init(_ table: String? = nil, columns: [String] = ["*"]) {
        super.init(db: .stub, table: table, columns: columns)
    }
}
