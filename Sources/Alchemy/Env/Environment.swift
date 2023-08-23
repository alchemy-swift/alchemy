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
public final class Environment: ExpressibleByStringLiteral {
    /// The environment file location of this application. Additional
    /// env variables are pulled from the file at '.{name}'. This
    /// defaults to `env`, `APP_ENV`, or `-e` / `--env` command
    /// line arguments.
    public let name: String
    /// The paths from which the dotenv file should be loaded.
    public let dotenvPaths: [String]
    /// All variables loaded from an environment file.
    public var dotenvVariables: [String: String]
    /// All environment variables available loaded from the process.
    public var processVariables: [String: String]

    public var isDebug: Bool {
        self.APP_DEBUG != false
    }

    public var isTesting: Bool {
        (isRunFromTests && self.APP_TEST != false) || self.APP_TEST == true
    }

    /// Whether the current program is running in a test suite. This is not the
    /// same as `isTesting` which returns whether the current env is meant for
    /// testing.
    public var isRunFromTests: Bool {
        Environment.isRunFromTests
    }

    /// Is this running from inside Xcode (vs the CLI).
    public var isXcode: Bool {
        Environment.isXcode
    }

    public init(name: String, dotenvPaths: [String]? = nil, dotenvVariables: [String: String] = [:], processVariables: [String: String] = [:]) {
        self.name = name
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
            Log.debug("No environment file found at `\(path)`.")
            return nil
        }

        let contents: String
        do {
            contents = try String(contentsOfFile: pathString, encoding: .utf8)
        } catch {
            Log.warning("Error loading contents of file at '\(pathString)': \(error).")
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

        Log.debug("Loaded environment variables from `\(path)`.")
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
            Log.comment("""
                **WARNING**

                Your project is running in Xcode's `DerivedData` data directory. It's _highly_ recommend that you set a custom working directory instead, otherwise files like `.env` and folders like `Public/` won't be accessible.

                It takes ~9 seconds to fix:

                Product -> Scheme -> Edit Scheme -> Run -> Options -> check 'use custom working directory' & choose the root directory of your project.
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
        Env.get(key, as: type)
    }

    /// Required for dynamic member lookup.
    public static subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        Env.get(member)
    }

    /// Required for dynamic member lookup.
    public subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        self.get(member)
    }

    public static var isRunFromTests: Bool {
        CommandLine.arguments.contains { $0.contains("xctest") }
    }

    public static var isXcode: Bool {
        CommandLine.arguments.contains { $0.contains("/Xcode/DerivedData") }
    }

    public static var `default`: Environment {
        isRunFromTests
            ? Environment(name: "test")
            : Environment(name: "dev", dotenvPaths: [".env"])
    }
}
