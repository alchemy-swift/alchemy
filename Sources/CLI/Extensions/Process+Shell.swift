import Foundation

struct ShellError: Error {
    let output: String
}

extension Process {
    /// Executes a shell command.
    ///
    /// - throws: `ShellError` if `standardError` isn't empty afterwards.
    func shell(_ command: String) throws -> String {
        self.launchPath = "/bin/bash"
        self.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        self.standardOutput = outputPipe
        self.standardError = errorPipe
        
        try self.run()
        
        self.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)

        if self.terminationStatus == 0 {
            return output
                .reduce("") { $0 + String($1) }
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw ShellError(output: error)
        }
    }
}
