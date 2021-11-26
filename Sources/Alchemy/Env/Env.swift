/// The env variable for an env path override.
private let kEnvVariable = "APP_ENV"
/// The default `.env` file location
private let kEnvDefault = "dev"
/// The default `.env` file location for tests
private let kEnvDefaultTest = "test"

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
public struct Env: Equatable, ExpressibleByStringLiteral {
    /// The current environment containing all variables loaded from
    /// the environment file.
    public internal(set) static var current = Env(name: kEnvDefault)
    
    public static let test: Env = Env(name: kEnvDefaultTest)
    public static let dev: Env = Env(name: kEnvDefault)
    public static let prod: Env = "prod"
    
    private static var didManuallyLoadDotEnv = false
    
    /// The environment file location of this application. Additional
    /// env variables are pulled from the file at '.{name}'. This
    /// defaults to `env`, `APP_ENV`, or `-e` / `--env` command
    /// line arguments.
    public let name: String
    
    /// All environment variables available to the application.
    public var dotEnvVariables: [String: String] = [:]
    
    /// All environment variables available to the application.
    public var processVariables: [String: String] = [:]
    
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
    
    init(name: String, dotEnvVariables: [String: String] = [:], processVariables: [String: String] = [:]) {
        self.name = name
        self.dotEnvVariables = dotEnvVariables
        self.processVariables = processVariables
    }
    
    /// Returns any environment variables loaded from the environment
    /// file as type `T: EnvAllowed`. Supports `String`, `Int`,
    /// `Double`, and `Bool`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to type `S`. `nil` if the
    ///   variable doesn't exist or it cannot be converted as `S`.
    public func get<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        guard let val = processVariables[key] ?? dotEnvVariables[key] else {
            return nil
        }
        
        return L(val)
    }
    
    /// Returns any environment variables from `Env.current` as type
    /// `T: StringInitializable`. Supports `String`, `Int`,
    /// `Double`, `Bool`, and `UUID`.
    ///
    /// - Parameter key: The name of the environment variable.
    /// - Returns: The variable converted to type `S`. `nil` if no fallback is
    ///   provided and the variable doesn't exist or cannot be converted as
    ///   `S`.
    public static func get<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        current.get(key)
    }
    
    /// Required for dynamic member lookup.
    public static subscript<L: LosslessStringConvertible>(dynamicMember member: String) -> L? {
        Env.get(member)
    }
    
    /// Boots the environment with the given arguments. Loads additional
    /// environment variables from a `.env` file.
    ///
    /// - Parameter args: The command line args of the program. -e or --env will
    ///   indicate a custom envfile location.
    static func boot(args: [String] = CommandLine.arguments, processEnv: [String: String] = ProcessInfo.processInfo.environment) {
        loadEnv(args: args, processEnv: processEnv)
        loadDotEnv()
    }
    
    static func loadEnv(args: [String] = CommandLine.arguments, processEnv: [String: String] = ProcessInfo.processInfo.environment) {
        var name = isRunningTests ? kEnvDefaultTest : kEnvDefault
        if let index = args.firstIndex(of: "--env"), let value = args[safe: index + 1] {
            name = value
        } else if let index = args.firstIndex(of: "-e"), let value = args[safe: index + 1] {
            name = value
        } else if let envName = processEnv[kEnvVariable] {
            name = envName
        }
        
        current = Env(name: name, processVariables: processEnv)
    }
    
    public static func loadDotEnv(_ paths: String...) {
        guard paths.isEmpty else {
            for path in paths {
                guard let values = loadDotEnvFile(path: path) else {
                    continue
                }
                
                for (key, value) in values {
                    current.dotEnvVariables[key] = value
                }
            }
            
            didManuallyLoadDotEnv = true
            return
        }
        
        guard !didManuallyLoadDotEnv else {
            return
        }
        
        let defaultPath = ".env"
        var overridePath: String? = nil
        if current.name != kEnvDefault {
            overridePath = ".env.\(current.name)"
        }
        
        if let overridePath = overridePath, let values = loadDotEnvFile(path: overridePath) {
            current.dotEnvVariables = values
        } else if let values = loadDotEnvFile(path: defaultPath) {
            current.dotEnvVariables = values
        } else {
            let overrideLocation = overridePath.map { "`\($0)` or " } ?? ""
            Log.info("[Environment] no env file found at \(overrideLocation)`\(defaultPath)`.")
        }
    }
}

extension Env {
    /// Load the environment file and put all the variables into the
    /// process environment.
    ///
    /// - Parameter path: The path of the file from which to load the
    ///   variables.
    private static func loadDotEnvFile(path: String) -> [String: String]? {
        let absolutePath = path.starts(with: "/") ? path : getAbsolutePath(relativePath: "/.\(path)")
        
        guard let pathString = absolutePath else {
            return nil
        }
        
        guard let contents = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            Log.info("[Environment] unable to load contents of file at '\(pathString)'")
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
        
        return values
    }

    /// Determines the absolute path of the given argument relative to
    /// the current directory. Return nil if there is no file at that
    /// path.
    ///
    /// - Parameter relativePath: The path to find.
    /// - Returns: The absolute path of the `relativePath`, if it
    ///   exists.
    private static func getAbsolutePath(relativePath: String) -> String? {
        warnIfUsingDerivedData()
        
        let fileManager = FileManager.default
        let filePath = fileManager.currentDirectoryPath + relativePath
        return fileManager.fileExists(atPath: filePath) ? filePath : nil
    }
    
    static func warnIfUsingDerivedData(_ directory: String = FileManager.default.currentDirectoryPath) {
        if directory.contains("/DerivedData") {
            Log.warning("""
                **WARNING**

                Your project is running in Xcode's `DerivedData` data directory. We _highly_ recommend setting a custom working directory, otherwise `.env` and `Public/` files won't be accessible.

                This takes ~9 seconds to fix. Here's how: https://github.com/alchemy-swift/alchemy/blob/main/Docs/1_Configuration.md#setting-a-custom-working-directory.
                """)
        }
    }
}

extension Env {
    public static var isProd: Bool {
        current == .prod
    }
    
    public static var isTest: Bool {
        current == .test
    }
    
    fileprivate static var isRunningTests: Bool {
        CommandLine.arguments.contains {
            $0.contains("xctest")
        }
    }
}
