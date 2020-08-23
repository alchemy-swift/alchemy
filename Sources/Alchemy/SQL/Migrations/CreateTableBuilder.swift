import Foundation

final class CreateTableBuilder: ColumnCreator, IndexCreator {
    var builders: [ColumnBuilderErased] = []
    var createIndexes: [CreateIndex] = []
}

final class ColumnBuilder<T: Sequelizable>: ColumnBuilderErased {
    private let name: String
    private let type: String
    private var modifiers: [String]
    
    init(name: String, type: String, modifiers: [String] = []) {
        self.name = name
        self.type = type
        self.modifiers = modifiers
    }
    
    @discardableResult func `default`(expression: String) -> Self {
        self.appending(modifier: "DEFAULT \(expression)")
    }
    
    @discardableResult func `default`(val: T) -> Self {
        self.appending(modifier: "DEFAULT \(val.toSQL().query)")
    }
    
    @discardableResult func nullable(_ isNullable: Bool = true) -> Self {
        guard !isNullable else {
            return self
        }
        
        return self.appending(modifier: "NOT NULL")
    }
    
    @discardableResult func references(_ column: String, on table: String) -> Self {
        self.appending(modifier: "REFERENCES \(table)(\(column))")
    }
    
    @discardableResult func primary() -> Self {
        self.appending(modifier: "PRIMARY KEY")
    }
    
    @discardableResult func unique() -> Self {
        self.appending(modifier: "UNIQUE")
    }
    
    private func appending(modifier: String) -> Self {
        self.modifiers.append(modifier)
        return self
    }
    
    func toCreate() -> CreateColumn {
        CreateColumn(column: self.name, type: self.type, constraints: self.modifiers)
    }
}

extension Bool: Sequelizable {
    func toSQL() -> SQL { SQL("\(self)") }
}

extension UUID: Sequelizable {
    func toSQL() -> SQL { SQL("'\(self.uuidString)'") }
}

extension String: Sequelizable {
    func toSQL() -> SQL { SQL("'\(self)'") }
}

extension Int: Sequelizable {
    func toSQL() -> SQL { SQL("\(self)") }
}

extension Double: Sequelizable {
    func toSQL() -> SQL { SQL("\(self)") }
}

extension Date: Sequelizable {
    private static let sqlFormatter = ISO8601DateFormatter()
    func toSQL() -> SQL { SQL("\(Date.sqlFormatter.string(from: self))") }
}

struct SQLJSON: Sequelizable {
    private var erased: () throws -> Data
    
    init<T: Encodable>(value: T, encoder: JSONEncoder = JSONEncoder()) {
        self.erased = { try encoder.encode(value) }
    }

    func toSQL() -> SQL {
        guard let data = try? self.erased() else {
            fatalError("Error encoding SQLJSON.")
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            fatalError("Error loading UTF8 string from SQLJSON.")
        }
        
        return SQL(string)
    }
}

extension Encodable {
    var sql: SQLJSON {
        SQLJSON(value: self)
    }
}
