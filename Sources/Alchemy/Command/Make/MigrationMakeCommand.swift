import ArgumentParser
import Foundation
import Pluralize

struct MigrationMakeCommand: Command {
    static var logStartAndFinish: Bool = false
    static var configuration = CommandConfiguration(
        commandName: "make:migration",
        discussion: "Create a new migration file"
    )
    
    @Argument var name: String
    @Argument var fields: [String] = []
    
    @Option(name: .shortAndLong) var table: String
    
    @IgnoreDecoding
    private var columns: [ColumnData]?
    
    init() {}
    init(name: String, table: String,  columns: [ColumnData]) {
        self.name = name
        self.table = table
        self.columns = columns
        self.fields = []
    }
    
    func start() throws {
        guard !name.contains(":") else {
            throw CommandError("Invalid migration name `\(name)`. Perhaps you forgot to pass a name?")
        }
        
        var migrationColumns: [ColumnData] = columns ?? []
        
        // Initialize rows
        if migrationColumns.isEmpty {
            migrationColumns = try fields.map(ColumnData.init)
            if migrationColumns.isEmpty { migrationColumns = .defaultData }
        }
        
        // Create files
        try createMigration(columns: migrationColumns)
    }
    
    private func createMigration(columns: [ColumnData]) throws {
        try FileCreator.shared.create(
            fileName: name,
            contents: migrationTemplate(name: name, columns: columns),
            in: "Database/Migrations",
            comment: "remember to add migration to your database config!")
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
        var returnString = "$0.\(type)(\(name.inQuotes))"

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
                
                returnString.append(".references(\(key.inQuotes), on: \(table.inQuotes))")
            default:
                throw CommandError("Unknown column modifier \(modifier)")
            }
        }
        
        return returnString
    }
}
