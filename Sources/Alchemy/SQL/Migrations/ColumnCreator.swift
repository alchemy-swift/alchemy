import Foundation

public class CreateTableBuilder {
    var createIndexes: [CreateIndex] = []
    var columnBuilders: [ColumnBuilderErased] = []
    
    var createColumns: [CreateColumn] {
        self.columnBuilders.map { $0.toCreate() }
    }
}

extension CreateTableBuilder {
    func addIndex(columns: [String], isUnique: Bool) {
        self.createIndexes.append(CreateIndex(columns: columns, isUnique: isUnique))
    }
}

struct CreateIndex {
    let columns: [String]
    let isUnique: Bool
}

struct CreateColumn {
    let column: String
    let type: String
    let constraints: [String]
    
    func toSQL() -> String {
        var baseSQL = "\(column) \(type)"
        if !constraints.isEmpty {
            baseSQL.append(" \(constraints.joined(separator: " "))")
        }
        return baseSQL
    }
}

extension CreateTableBuilder {
    @discardableResult public func increments(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "int"))
    }
    
    @discardableResult public func int(_ column: String) -> CreateColumnBuilder<Int> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "int"))
    }
    
    @discardableResult public func double(_ column: String) -> CreateColumnBuilder<Double> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "float8"))
    }
    
    @discardableResult public func string(_ column: String) -> CreateColumnBuilder<String> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "text"))
    }
    
    @discardableResult public func uuid(_ column: String) -> CreateColumnBuilder<UUID> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "uuid"))
    }
    
    @discardableResult public func bool(_ column: String) -> CreateColumnBuilder<Bool> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "bool"))
    }
    
    @discardableResult public func timestamp(_ column: String) -> CreateColumnBuilder<Date> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "timestampz"))
    }
    
    @discardableResult public func json(_ column: String) -> CreateColumnBuilder<SQLJSON> {
        self.appendAndReturn(builder: CreateColumnBuilder(name: column, type: "json"))
    }
    
    private func appendAndReturn<T: Sequelizable>(builder: CreateColumnBuilder<T>) -> CreateColumnBuilder<T> {
        self.columnBuilders.append(builder)
        return builder
    }
}

protocol ColumnBuilderErased {
    func toCreate() -> CreateColumn
}
