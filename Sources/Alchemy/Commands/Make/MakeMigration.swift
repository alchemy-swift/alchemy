import ArgumentParser
import Foundation
import Pluralize

struct MakeMigration: Command {
    static var logStartAndFinish: Bool = false
    static var configuration = CommandConfiguration(
        commandName: "make:migration",
        discussion: "Create a new migration file"
    )
    
    @Argument var name: String
    @Argument var fields: [String] = []
    
    @Option(name: .shortAndLong) var table: String
    
    private var columns: [ColumnData] = []
    
    init() {}
    
    init(name: String, table: String, columns: [ColumnData]) {
        self.name = name
        self.table = table
        self.columns = columns
    }
    
    func start() throws {
        guard !name.contains(":") else {
            throw CommandError("Invalid migration name `\(name)`. Perhaps you forgot to pass a name?")
        }
        
        var migrationColumns: [ColumnData] = columns
        
        // Initialize rows
        if migrationColumns.isEmpty {
            migrationColumns = try fields.map(ColumnData.init)
            if migrationColumns.isEmpty { migrationColumns = .defaultData }
        }
        
        // Create files
        try createMigration(columns: migrationColumns)
    }
    
    private func createMigration(columns: [ColumnData]) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let fileName = "\(dateFormatter.string(from: Date()))\(name)"
        try FileCreator.shared.create(
            fileName: fileName,
            contents: migrationTemplate(name: name, columns: columns),
            in: "Migrations",
            comment: "remember to add migration to a Database.migrations!")
    }
    
    private func migrationTemplate(name: String, columns: [ColumnData]) throws -> String {
        let fields = try columns.map { try $0.migrationRowString() }.joined(separator: "\n\t\t\t")
        
        return """
        import Alchemy
        
        struct \(name): Migration {
            func up(schema: Schema) {
                schema.create(table: "\(table)") {
                    \(fields)
                }
            }
            
            func down(schema: Schema) {
                schema.drop(table: "\(table)")
            }
        }
        """
    }
}

private extension ColumnData {
    func migrationRowString() throws -> String {
        var returnString = "$0.\(type)(\"\(name)\")"
        
        for modifier in modifiers.map({ String($0) }) {
            let splitComponents = modifier.split(separator: ".")
            guard let modifier = splitComponents.first else {
                throw CommandError("There was an empty field modifier.")
            }
            
            switch modifier.lowercased() {
            case "primary":
                returnString.append(".primary()")
            case "unique":
                returnString.append(".unique()")
            case "notnull":
                returnString.append(".notNull()")
            case "references":
                guard
                    let table = splitComponents[safe: 1],
                    let key = splitComponents[safe: 2]
                else {
                    throw CommandError("Invalid references format `\(modifier)` expected `references.table.key`")
                }
                
                returnString.append(".references(\"\(key)\", on: \"\(table)\")")
            default:
                throw CommandError("Unknown column modifier \(modifier)")
            }
        }
        
        return returnString
    }
}
