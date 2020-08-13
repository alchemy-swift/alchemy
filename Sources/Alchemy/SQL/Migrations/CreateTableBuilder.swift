import Foundation

protocol ColumnCreator {}

struct CreateTableBuilder: ColumnCreator {
    var createColumns: [CreateColumn] = []
}

extension ColumnCreator {
    @discardableResult func increments(_ column: String) -> ColumnBuilder<Int> {
        ColumnBuilder(name: column, type: "int")
    }
    
    @discardableResult func int(_ column: String) -> ColumnBuilder<Int> {
        ColumnBuilder(name: column, type: "int")
    }
    
    @discardableResult func double(_ column: String) -> ColumnBuilder<Double> {
        ColumnBuilder(name: column, type: "float8")
    }
    
    @discardableResult func string(_ column: String) -> ColumnBuilder<String> {
        ColumnBuilder(name: column, type: "text")
    }
    
    @discardableResult func text(_ column: String) -> ColumnBuilder<String> {
        ColumnBuilder(name: column, type: "text")
    }
    
    @discardableResult func uuid(_ column: String) -> ColumnBuilder<UUID> {
        ColumnBuilder(name: column, type: "uuid")
    }
    
    @discardableResult func bool(_ column: String) -> ColumnBuilder<Bool> {
        ColumnBuilder(name: column, type: "bool")
    }
    
    @discardableResult func timestamp(_ column: String) -> ColumnBuilder<Date> {
        ColumnBuilder(name: column, type: "timestampz")
    }
    
    @discardableResult func json(_ column: String) -> ColumnBuilder<SQLJSON> {
        ColumnBuilder(name: column, type: "json")
    }
}

struct ColumnBuilder<T: Sequelizable> {
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
        self.appending(modifier: "DEFAULT \(val.toSQL())")
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
    
    @discardableResult func index() -> Self {
        // TODO, maybe should @ table level ?
        self.appending(modifier: "todo")
    }
    
    private func appending(modifier: String) -> Self {
        var this = self
        this.modifiers.append(modifier)
        return this
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
