/// The default env file path (will be prefixed by a .).
private let kDefaultEnv = "env"

/// The env variable for an env path override.
private let kEnvVariable = "APP_ENV"

/// Handles any environment info of your application. Loads any
/// environment variables from the file a `.env` or `.{APP_ENV}`
/// if `APP_ENV` is set in the current environment.
///
/// Variables are accessed via `.get`. Supports dynamic member lookup.
/// ```swift
/// // .env file:
/// SOME_KEY=secret_value
/// OTHER_KEY=123456
///
/// // Swift code
/// let someVariable: String? = Env.current.get("SOME_KEY")
///
/// // Dynamic member lookup
/// let otherVariable: Int? = Env.OTHER_KEY
/// ```
@dynamicMemberLookup
public struct Env: Equatable {
    /// The environment file location of this application. Additional
    /// env variables are pulled from the file at '.{name}'. This
    /// defaults to `env` or `APP_ENV` if that is set.
    public let name: String
    
    /// Returns any environment variables loaded from the environment
    /// file as type `T: EnvAllowed`. Supports `String`, `Int`,
    /// `Double`, and `Bool`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to type `S`. `nil` if the
    ///   variable doesn't exist or it cannot be converted as `S`.
    public func get<S: StringInitializable>(_ key: String) -> S? {
        if let val = getenv(key) {
            let stringValue = String(validatingUTF8: val)
            return stringValue.map { S($0) } ?? nil
        }
        return nil
    }
    
    /// Required for dynamic member lookup.
    public static subscript<T: StringInitializable>(dynamicMember member: String) -> T? {
        Env.current.get(member)
    }
    
    /// All environment variables available to the program.
    public var all: [String: String] {
        return ProcessInfo.processInfo.environment
    }
    
    /// The current environment containing all variables loaded from
    /// the environment file.
    public static var current: Env = {
        let appEnvPath = ProcessInfo.processInfo
            .environment[kEnvVariable] ?? kDefaultEnv
        Env.loadDotEnvFile(path: ".\(appEnvPath)")
        return Env(name: appEnvPath)
    }()
}

extension Env {
    /// Load the environment file and put all the variables into the
    /// process environment.
    ///
    /// - Parameter path: The path of the file from which to load the
    ///   variables.
    private static func loadDotEnvFile(path: String) {
        let absolutePath = path.starts(with: "/") ? path : getAbsolutePath(relativePath: "/\(path)")
        
        guard let pathString = absolutePath else {
            return Log.info("[Environment] no file found at '\(path)'")
        }
        
        guard let contents = try? NSString(contentsOfFile: pathString, encoding: String.Encoding.utf8.rawValue) else {
            return Log.info("[Environment] unable to load contents of file at '\(pathString)'")
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

    /// Determines the absolute path of the given argument relative to
    /// the current directory. Return nil if there is no file at that
    /// path.
    ///
    /// - Parameter relativePath: The path to find.
    /// - Returns: The absolute path of the `relativePath`, if it
    ///   exists.
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
