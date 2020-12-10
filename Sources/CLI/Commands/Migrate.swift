import ArgumentParser
import Foundation

struct MigrationError: Error {
    let info: String
    
    var description: String {
        self.info
    }
}

struct Migrate: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "migrate",
        subcommands: [New.self]
    )
    
    struct New: ParsableCommand {
        @Argument
        var name: String
        
        func run() throws {
            guard let migrationLocations = try? Process().shell("find Sources -type d -name 'Migrations'").split(separator: "\n"),
                  let migrationLocation = migrationLocations.first else
            {
                throw MigrationError(info: "No 'Migrations/' directory found. Please ensure you're in an Alchemy project directory.")
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            let fileName = "_\(dateFormatter.string(from: Date()))\(name)"
            let template = self.migrationTemplate(name: fileName)

            let destinationURL = URL(fileURLWithPath: "\(migrationLocation)/\(fileName).swift")
            try template.write(to: destinationURL, atomically: true, encoding: .utf8)
            print("Created migration '\(fileName)' at \(migrationLocation)")
        }
        
        private func migrationTemplate(name: String) -> String {
            """
            struct \(name): Migration {
                func up(schema: Schema) {
                    schema.create(table: "users") {
                        $0.uuid("id").primary()
                        $0.string("name").nullable(false)
                        $0.string("email").nullable(false).unique()
                    }
                }
                
                func down(schema: Schema) {
                    schema.drop(table: "users")
                }
            }
            """
        }
    }
}

