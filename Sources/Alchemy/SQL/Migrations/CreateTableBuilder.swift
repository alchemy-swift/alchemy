import Foundation

protocol ColumnCreator {}

struct CreateTableBuilder: ColumnCreator {
    var createColumns: [CreateColumn] = []
}

extension ColumnCreator {
    @discardableResult func increments(_ column: String) -> ColumnBuilder<Int> { ColumnBuilder(name: column) }
    @discardableResult func int(_ column: String) -> ColumnBuilder<Int> { ColumnBuilder(name: column) }
    @discardableResult func double(_ column: String) -> ColumnBuilder<Double> { ColumnBuilder(name: column) }
    @discardableResult func string(_ column: String) -> ColumnBuilder<String> { ColumnBuilder(name: column) }
    @discardableResult func text(_ column: String) -> ColumnBuilder<String> { ColumnBuilder(name: column) }
    @discardableResult func uuid(_ column: String) -> ColumnBuilder<UUID> { ColumnBuilder(name: column) }
    @discardableResult func bool(_ column: String) -> ColumnBuilder<Bool> { ColumnBuilder(name: column) }
    @discardableResult func timestamp(_ column: String) -> ColumnBuilder<Date> { ColumnBuilder(name: column) }
    @discardableResult func json(_ column: String) -> ColumnBuilder<Encodable> { ColumnBuilder(name: column) }
}

struct ColumnBuilder<T> {
    private let name: String
    
    init(name: String) {
        self.name = name
    }
    
    @discardableResult func `default`(expression: String) -> Self { self }
    @discardableResult func `default`(val: T) -> Self { self }
    @discardableResult func nullable(_ isNullable: Bool = true) -> Self { self }
    @discardableResult func references(_ column: String, on table: String) -> Self { self }
    
    @discardableResult func primary() -> Self { self }
    @discardableResult func unique() -> Self { self }
    @discardableResult func index() -> Self { self }
}
