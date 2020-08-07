private let kDefaultEnv = "env"
private let kEnvVariable = "APP_ENV"

@dynamicMemberLookup
public struct Env: Equatable {
    /// The APP_ENV of this process. Additional env variables are pulled from the file at
    /// '.\(APP_ENV)'.
    ///
    /// Defaults to 'env' if there is APP_ENV is empty.
    public let name: String
    
    public func get<T: EnvAllowed>(_ key: String) -> T? {
        if let val = getenv(key) {
            return String(validatingUTF8: val).map { T.from($0) }
        }
        return nil
    }
    
    public static subscript<T: EnvAllowed>(dynamicMember member: String) -> T? {
        Env.current.get(member)
    }
    
    public var all: [String: String] {
        return ProcessInfo.processInfo.environment
    }
    
    public static var current: Env = {
        let appEnvPath = ProcessInfo.processInfo.environment[kEnvVariable] ?? kDefaultEnv
        Env.loadDotEnvFile(path: ".\(appEnvPath)")
        return Env(name: appEnvPath)
    }()
}

extension Env {
    /// Load .env file and put all the variables into the environment
    private static func loadDotEnvFile(path: String) {
        let absolutePath = path.starts(with: "/") ? path : getAbsolutePath(relativePath: "/\(path)")
        
        guard let pathString = absolutePath else {
            return Log.info("No file found at '\(path)'")
        }
        
        guard let contents = try? NSString(contentsOfFile: pathString, encoding: String.Encoding.utf8.rawValue) else {
            return Log.info("Unable to load contents of file at '\(pathString)'")
        }
        
        let lines = String(describing: contents).split { $0 == "\n" || $0 == "\r\n" }.map(String.init)
        for line in lines {
            // ignore comments
            if line[line.startIndex] == "#" {
                continue
            }

            // ignore lines that appear empty
            if line.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).isEmpty {
                continue
            }

            // extract key and value which are separated by an equals sign
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)

            guard parts.count > 0 else {
                continue
            }
            
            let key = parts[0].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            let val = parts[safe: 1]?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            guard var value = val else {
                continue
            }
            
            // remove surrounding quotes from value & convert remove escape character before any embedded quotes
            if value[value.startIndex] == "\"" && value[value.index(before: value.endIndex)] == "\"" {
                value.remove(at: value.startIndex)
                value.remove(at: value.index(before: value.endIndex))
                value = value.replacingOccurrences(of:"\\\"", with: "\"")
            }
            setenv(key, value, 1)
        }
    }

    /// Determine absolute path of the given argument relative to the current
    /// directory. Return nil if no file at that path.
    private static func getAbsolutePath(relativePath: String) -> String? {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let filePath = currentPath + relativePath
        if fileManager.fileExists(atPath: filePath) {
            return filePath
        } else {
            return nil
        }
    }
}
