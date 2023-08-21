import Foundation

struct Terminal {
    static var columns: Int = {
        let string = try! safeShell("tput cols").trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(string) ?? 80
    }()

    @discardableResult
    private static func safeShell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.standardInput = nil

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}
