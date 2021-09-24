import ArgumentParser
import Foundation
import Papyrus

typealias Flag = ArgumentParser.Flag
typealias Option = ArgumentParser.Option

struct MakeModel: Command {
    static var logStartAndFinish: Bool = false
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
    
    func start() -> EventLoopFuture<Void> {
        catchError {
            guard !name.contains(":") else {
                throw CommandError(message: "Invalid model name `\(name)`. Perhaps you forgot to pass a name?")
            }
            
            // Initialize rows
            var columns = try fields.map(ColumnData.init)
            if columns.isEmpty { columns = .defaultData }
            
            // Create files
            try createModel(columns: columns)
            
            let migrationFuture = migration ? MakeMigration(
                name: "Create\(name.pluralized)",
                table: name.camelCaseToSnakeCase().pluralized,
                columns: columns
            ).start() : .new()
            
            let controllerFuture = controller ? MakeController(model: name).start() : .new()
            return migrationFuture.flatMap { controllerFuture }
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
        
        if name == "id" {
            return "var \(name.snakeCaseToCamelCase()): \(swiftType)"
        } else {
            return "let \(name.snakeCaseToCamelCase()): \(swiftType)"
        }
    }
}

extension String {
    func camelCaseToSnakeCase() -> String {
        KeyMapping.snakeCase.mapTo(input: self)
    }
    
    func snakeCaseToCamelCase() -> String {
        KeyMapping.snakeCase.mapFrom(input: self)
    }
}
