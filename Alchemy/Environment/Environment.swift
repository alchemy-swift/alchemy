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
/// ```
@dynamicMemberLookup
public final class Environment: ExpressibleByStringLiteral {
    /// The name of the environment.
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

    /// Required for dynamic member lookup.
    public subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        self.get(member)
    }

    /// Returns any environment variables with the given key as `L`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to `L` or `nil` if the variable
    ///   doesn't exist or it cannot be converted to `L`.
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

    public static var isRunFromTests: Bool {
        CommandLine.arguments.contains { $0.contains("xctest") }
    }

    public static var isXcode: Bool {
        CommandLine.arguments.contains {
            $0.contains("/Xcode/DerivedData") ||
            $0.contains("/Xcode/Agents")
        }
    }

    public static func createDefault() -> Environment {
        let env: Environment
        if
            let name = CommandLine.value(for: "--env") ??
                CommandLine.value(for: "-e") ??
                ProcessInfo.processInfo.environment["APP_ENV"] {
            env = Environment(name: name)
        } else {
            env = isRunFromTests
                ? Environment(name: "test")
                : Environment(name: "local", dotenvPaths: [".env"])
        }

        env.loadVariables()
        return env
    }
}
