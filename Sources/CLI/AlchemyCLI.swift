import ArgumentParser
import Foundation

struct AlchemyCLI: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "An Alchemy CLI.",
            subcommands: [NewProject.self, Migrate.self]
        )
    }
}
