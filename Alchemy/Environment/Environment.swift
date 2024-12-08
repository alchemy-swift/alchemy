import Foundation

/// Handles any environment info of your application. Loads any environment
/// variables from the file a `.env` or `.env.{APP_ENV}` if `APP_ENV` is
/// set in the current environment.
///
/// Variables are accessed via `.get`. Supports dynamic member lookup.
/// ```swift
/// // .env file:
/// SOME_KEY=secret_value
/// OTHER_KEY=123456
///
/// // Swift code
/// let someVariable: String? = Env.get("SOME_KEY")
///
/// // Dynamic member lookup
/// let otherVariable: Int? = Env.OTHER_KEY
///
/// @Env var dbHost: Int = 5432 // loads `DB_HOST` from env if it exists,
///                             // otherwise defaults to 5432
/// ```
public final class Environment: ExpressibleByStringLiteral {
    /// The name of the environment.
    public var name: String
    /// The paths from which the dotenv file should be loaded.
    public var dotenvPaths: [String]
    /// All variables loaded from an environment file.
    public var dotenvVariables: [String: String]
    /// All environment variables available loaded from the process.
    public var processVariables: [String: String]
    /// All runtime overrides for environment variables.
    public var runtimeOverrides: [String: String] = [:]

    @Env("APP_DEBUG") public var isDebug = true
    @Env              private var appTest: Bool?

    public var isTesting: Bool {
        appTest ?? Container.isTest
    }

    public init(name: String, dotenvPaths: [String]? = nil, dotenvVariables: [String: String] = [:], processVariables: [String: String] = [:]) {
        self.name = name
        self.dotenvPaths = dotenvPaths ?? [".env.\(name)"]
        self.dotenvVariables = dotenvVariables
        self.processVariables = processVariables
        self.runtimeOverrides = [:]
    }

    public convenience init(stringLiteral value: String) {
        self.init(name: value)
    }

    // MARK: Access

    /// Returns any environment variables with the given key as `L`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to `L` or `nil` if the variable
    ///   doesn't exist or it cannot be converted to `L`.
    public func get<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        guard let val =  runtimeOverrides[key] ?? processVariables[key] ?? dotenvVariables[key] else {
            return nil
        }

        return L(val)
    }

    public func require<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self, default: L? = nil) -> L {
        guard let val = runtimeOverrides[key] ?? processVariables[key] ?? dotenvVariables[key] else {
            guard let `default` else { fatalError("No environment value for \(key) found.") }
            return `default`
        }

        guard let value = L(val) else {
            guard let `default` else { fatalError("Environment value for \(key) is not a valid \(L.self).") }
            return `default`
        }

        return value
    }

    public func require<L: LosslessStringConvertible>(_ key: String, as: L?.Type = L?.self, default: L? = nil) -> L? {
        guard let val = processVariables[key] ?? dotenvVariables[key] else { return `default` }
        guard let value = L(val) else { return `default` }
        return value
    }

    // MARK: Runtime Overriding

    public func override<L: LosslessStringConvertible>(_ key: String, with value: L) {
        runtimeOverrides[key] = value.description
    }

    public func override<L: LosslessStringConvertible>(_ key: String, with value: L?) {
        runtimeOverrides[key] = value?.description
    }

    // MARK: Loading

    /// Loads variables from the process & any environment file.
    public func loadVariables() {
        processVariables = ProcessInfo.processInfo.environment
        dotenvVariables = dotenvPaths
            .compactMap(loadDotEnvFile)
            .reduce([:], +)
    }

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

    /// Determines the absolute path of the given argument relative to the
    /// current directory. Return nil if there is no file at that path.
    private func getAbsolutePath(relativePath: String) -> String? {
        let fileManager = FileManager.default
        let filePath = fileManager.currentDirectoryPath + relativePath
        if filePath.contains("/DerivedData") {
            let warning = """
                **WARNING**

                Your project is running in Xcode's `DerivedData` data directory. It's _highly_ recommend that you set a custom working directory instead, otherwise files like `.env` and folders like `Public/` won't be accessible.

                It takes ~9 seconds to fix:

                Product -> Scheme -> Edit Scheme -> Run -> Options -> check 'use custom working directory' & choose the root directory of your project.
                """
            if Container.isXcode {
                Log.warning(warning)
            } else {
                Log.comment(warning.yellow)
            }
        }

        return fileManager.fileExists(atPath: filePath) ? filePath : nil
    }

    // MARK: Helpers

    public static func createDefault() -> Environment {
        let env: Environment
        if
            let name = CommandLine.value(for: "--env") ??
                CommandLine.value(for: "-e") ??
                ProcessInfo.processInfo.environment["APP_ENV"] {
            env = Environment(name: name)
        } else {
            env = Container.isTest
                ? Environment(name: "test")
                : Environment(name: "local", dotenvPaths: [".env"])
        }

        env.loadVariables()
        return env
    }
}
