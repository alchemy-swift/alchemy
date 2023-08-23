import ArgumentParser
import Foundation

typealias Flag = ArgumentParser.Flag
typealias Option = ArgumentParser.Option

final class ModelMakeCommand: Command {
    static var configuration = CommandConfiguration(
        commandName: "make:model",
        discussion: """
            Create a new Rune model.
            
            You can optionally pass field arguments to generate the model and migration with. Each field argument needs a name and type separated by a colon. It can also have any number of modifiers that will be used in generating any migrations.
            
            e.g. name:string, email:string:unique, user_id:bigint:references.users.id
            
            Available types: increments, int, bigint, string, date, json, double, uuid, bool
            
            Available modifiers: primary, unique, notnull, references.table.key
            """
    )
    
    @Argument(help: "The model name.") var name: String
    @Argument(help: "Any fields to generate the model & optional migration with. In the form of <name>:<type>:<modifiers...>") var fields: [String] = []
    
    @Flag(name: .shortAndLong, help: "Also make a migration file for this model.") var migration: Bool = false
    @Flag(name: .shortAndLong, help: "Also make a controller with CRUD operations for this model.") var controller: Bool = false
    
    @IgnoreDecoding
    private var columns: [ColumnData]?
    
    init() {}
    init(name: String, columns: [ColumnData] = [], migration: Bool = false, controller: Bool = false) {
        self.name = name
        self.columns = columns
        self.fields = []
        self.migration = migration
        self.controller = controller
    }
    
    func run() throws {
        guard !name.contains(":") else {
            throw CommandError("Invalid model name `\(name)`. Perhaps you forgot to pass a name?")
        }
        
        // Initialize rows
        if (columns ?? []).isEmpty && fields.isEmpty {
            columns = .defaultData
        } else if (columns ?? []).isEmpty {
            columns = try fields.map(ColumnData.init)
        }
        
        // Create files
        try createModel(columns: columns ?? [])
        
        if migration {
            try MigrationMakeCommand(
                name: "Create\(name.pluralized)",
                table: KeyMapping.snakeCase.encode(name).pluralized,
                columns: columns ?? []
            ).run()
        }
        
        if controller {
            try ControllerMakeCommand(model: name).run()
        }
    }
    
    private func createModel(columns: [ColumnData]) throws {
        try FileCreator.shared.create(fileName: name, contents: modelTemplate(name: name, columns: columns), in: "Models")
    }
    
    private func modelTemplate(name: String, columns: [ColumnData]) -> String {
        let properties = columns.map { $0.modelPropertyString() }.joined(separator: "\n\t")
        
        return """
        import Alchemy
        
        struct \(name): Model {
            \(properties)
        }
        """
    }
}

private extension ColumnData {
    func modelPropertyString() -> String {
        var swiftType: String
        switch type {
        case "increments", "int", "bigInt":
            swiftType = "Int"
        case "double":
            swiftType = "Double"
        case "string":
            swiftType = "String"
        case "uuid":
            swiftType = "UUID"
        case "bool":
            swiftType = "Bool"
        case "date":
            swiftType = "Date"
        case "json":
            swiftType = "CustomType"
        default:
            swiftType = "String"
        }
        
        if !modifiers.map({ $0.lowercased() }).contains("notnull") {
            swiftType += "?"
        }
        
        let declaration = name == "id" ? "var" : "let"
        let name = KeyMapping.snakeCase.decode(name)
        return "\(declaration) \(name): \(swiftType)"
    }
}
