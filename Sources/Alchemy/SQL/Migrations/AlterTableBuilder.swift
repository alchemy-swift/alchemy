import Foundation

struct AlterTableBuilder: TableBuilder, ColumnCreator {
    func sql() -> String {
        ""
    }
}

extension AlterTableBuilder {
    func drop(column: String) {}
    func rename(column: String, to: String) {}
}
