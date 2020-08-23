import Foundation

protocol ColumnCreator: class {
    var builders: [ColumnBuilderErased] { get set }
}

extension ColumnCreator {
    var createColumns: [CreateColumn] {
        self.builders.map { $0.toCreate() }
    }
}

extension ColumnCreator {
    private func appendAndReturn<T: Sequelizable>(builder: ColumnBuilder<T>) -> ColumnBuilder<T> {
        self.builders.append(builder)
        return builder
    }
    
    @discardableResult func increments(_ column: String) -> ColumnBuilder<Int> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "int"))
    }
    
    @discardableResult func int(_ column: String) -> ColumnBuilder<Int> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "int"))
    }
    
    @discardableResult func double(_ column: String) -> ColumnBuilder<Double> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "float8"))
    }
    
    @discardableResult func string(_ column: String) -> ColumnBuilder<String> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "text"))
    }
    
    @discardableResult func uuid(_ column: String) -> ColumnBuilder<UUID> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "uuid"))
    }
    
    @discardableResult func bool(_ column: String) -> ColumnBuilder<Bool> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "bool"))
    }
    
    @discardableResult func timestamp(_ column: String) -> ColumnBuilder<Date> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "timestampz"))
    }
    
    @discardableResult func json(_ column: String) -> ColumnBuilder<SQLJSON> {
        self.appendAndReturn(builder: ColumnBuilder(name: column, type: "json"))
    }
}

protocol ColumnBuilderErased {
    func toCreate() -> CreateColumn
}
