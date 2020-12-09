import ArgumentParser
import Foundation

struct AlchemyCLI: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "An Alchemy CLI.",
            subcommands: [Serve<A>.self, Migrate<A>.self],
            defaultSubcommand: Serve<A>.self
        )
    }
}

struct New: ParsableCommand {
    func run() throws {
        let string = Process().shell("echo hello")
        print("string: \(string)")
    }
}

extension Process {
    func shell(_ command: String) -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        let outputPipe = Pipe()
        standardOutput = outputPipe
        launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let outputData = String(data: data, encoding: String.Encoding.utf8) else { return "" }

        return outputData.reduce("") { (result, value) in
            return result + String(value)
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
