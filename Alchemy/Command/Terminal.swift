struct Terminal {
    static var columns: Int = {
        guard let string = try? shell("tput cols").trimmingCharacters(in: .whitespacesAndNewlines), let columns = Int(string) else {
            return 80
        }

        return columns
    }()

    @discardableResult
    private static func shell(_ command: String) throws -> String {
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
