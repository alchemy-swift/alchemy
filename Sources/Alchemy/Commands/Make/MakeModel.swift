import ArgumentParser
import Foundation
import Papyrus

typealias Flag = ArgumentParser.Flag
typealias Option = ArgumentParser.Option

struct MakeModel: Command {
    static var configuration = CommandConfiguration(
        commandName: "make:model",
        discussion: "Create a new Rune model"
    )
    
    @Argument var name: String
    @Argument var fields: [String] = []
    
    @Flag(name: .shortAndLong) var migration: Bool = false
    @Flag(name: .shortAndLong) var controller: Bool = false
    
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
