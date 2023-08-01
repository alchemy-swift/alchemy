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
public final class Environment: Equatable, ExpressibleByStringLiteral {
    /// The environment file location of this application. Additional
    /// env variables are pulled from the file at '.{name}'. This
    /// defaults to `env`, `APP_ENV`, or `-e` / `--env` command
    /// line arguments.
    public let name: String

    /// Indicates if the current application environment is a test.
    public let isTesting: Bool

    /// The paths from which the dotenv file should be loaded.
    public let dotenvPaths: [String]

    /// All variables loaded from an environment file.
    public var dotenvVariables: [String: String]

    /// All environment variables available loaded from the process.
    public var processVariables: [String: String]

    public init(name: String, isTesting: Bool = false, dotenvPaths: [String]? = nil, dotenvVariables: [String: String] = [:], processVariables: [String: String] = [:]) {
        self.name = name
        self.isTesting = isTesting
        self.dotenvPaths = dotenvPaths ?? [".env.\(name)"]
        self.dotenvVariables = dotenvVariables
        self.processVariables = processVariables
    }

    public convenience init(stringLiteral value: String) {
        self.init(name: value)
    }

    /// Returns any environment variables loaded from the environment
    /// file as type `T: EnvAllowed`. Supports `String`, `Int`,
    /// `Double`, and `Bool`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to type `S`. `nil` if the
    ///   variable doesn't exist or it cannot be converted as `S`.
    public func get<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        guard let val = processVariables[key] ?? dotenvVariables[key] else {
            return nil
        }
        
        return L(val)
    }
    
    /// Loads variables from the process & any environment file.
    public func loadVariables() {
        processVariables = ProcessInfo.processInfo.environment
        dotenvVariables = dotenvPaths
            .compactMap(loadDotEnvFile)
            .reduce([:], +)
    }

    /// Load the environment file and put all the variables into the
    /// process environment.
    ///
    /// - Parameter path: The path of the file from which to load the
    ///   variables.
    private func loadDotEnvFile(path: String) -> [String: String]? {
        let absolutePath = path.starts(with: "/") ? path : getAbsolutePath(relativePath: "/\(path)")

        guard let pathString = absolutePath else {
            Log.debug("[Environment] No environment file found at `\(path)`.")
            return nil
        }

        guard let contents = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            Log.warning("[Environment] unable to load contents of file at '\(pathString)'")
            return [:]
        }

        var values: [String: String] = [:]
        let lines = contents.split { $0 == "\n" || $0 == "\r\n" }.map(String.init)
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
            let key = parts[0].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            let val = parts[safe: 1]?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            guard var value = val else {
                continue
            }

            // remove surrounding quotes from value & convert remove escape character before any embedded quotes
            if value[value.startIndex] == "\"" && value[value.index(before: value.endIndex)] == "\"" {
                value.remove(at: value.startIndex)
                value.remove(at: value.index(before: value.endIndex))
            }

            values[key] = value
        }

        Log.debug("[Environment] Loaded environment variables from `\(path)`.")
        return values
    }

    /// Determines the absolute path of the given argument relative to
    /// the current directory. Return nil if there is no file at that
    /// path.
    ///
    /// - Parameter relativePath: The path to find.
    /// - Returns: The absolute path of the `relativePath`, if it
    ///   exists.
    private func getAbsolutePath(relativePath: String) -> String? {
        if relativePath.contains("/DerivedData") {
            Log.warning("""
                **WARNING**

                Your project is running in Xcode's `DerivedData` data directory. It's _highly_ recommend that you set a custom working directory instead, otherwise files like `.env` and `Public/` won't be accessible.

                It takes ~9 seconds to fix. Here's how: https://github.com/alchemy-swift/alchemy/blob/main/Docs/1_Configuration.md#setting-a-custom-working-directory.
                """.yellow)
        }

        let fileManager = FileManager.default
        let filePath = fileManager.currentDirectoryPath + relativePath
        return fileManager.fileExists(atPath: filePath) ? filePath : nil
    }

    /// Returns any environment variables from `Env.current` as type
    /// `T: StringInitializable`. Supports `String`, `Int`,
    /// `Double`, `Bool`, and `UUID`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to type `S`. `nil` if no fallback is
    ///   provided and the variable doesn't exist or cannot be converted as
    ///   `S`.
    public static func get<L: LosslessStringConvertible>(_ key: String, as type: L.Type = L.self) -> L? {
        Container.main.env.get(key, as: type)
    }

    /// Required for dynamic member lookup.
    public static subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        Environment.get(member)
    }

    /// Required for dynamic member lookup.
    public subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        self.get(member)
    }

    public static var isTesting: Bool {
        Container.main.env.isTesting
    }

    /// Whether the current program is running in a test suite. This is not the
    /// same as `isTest` which returns whether the current env is for testing.
    public static var isRunningTests: Bool {
        CommandLine.arguments.contains { $0.contains("xctest") }
    }

    public static var `default`: Environment {
        isRunningTests
            ? Environment(name: "test", isTesting: true)
            : Environment(name: "dev", dotenvPaths: [".env"])
    }

    // MARK: Equatable

    public static func == (lhs: Environment, rhs: Environment) -> Bool {
        lhs.name == rhs.name
    }
}
