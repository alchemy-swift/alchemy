struct ColumnData: Codable {
    let name: String
    let type: String
    let modifiers: [String]
    
    init(name: String, type: String, modifiers: [String]) {
        self.name = name
        self.type = type
        self.modifiers = modifiers
    }
    
    init(from input: String) throws {
        let components = input.split(separator: ":").map(String.init)
        guard components.count >= 2 else {
            throw CommandError(message: "Invalid field: \(input). Need at least name and type, such as `name:string`")
        }
        
        let name = components[0]
        var type = components[1]
        let modifiers = components[2...]
        
        switch type.lowercased() {
        case "increments", "int", "double", "string", "uuid", "bool", "date", "json":
            type = type.lowercased()
        case "bigint":
            type = "bigInt"
        default:
            throw CommandError(message: "Unknown field type `\(type)`")
        }
        
        self.name = name
        self.type = type
        self.modifiers = modifiers.map({ String($0) })
    }
}

extension Array where Element == ColumnData {
    static var defaultData: [ColumnData] = [
        ColumnData(name: "id", type: "increments", modifiers: ["notNull"]),
        ColumnData(name: "name", type: "string", modifiers: ["notNull"]),
        ColumnData(name: "email", type: "string", modifiers: ["notNull", "unique"]),
        ColumnData(name: "password", type: "string", modifiers: ["notNull"]),
    ]
}
