public struct Environment: Equatable {
    public let name: String
    
    public static let testing = Environment(name: "testing")
    public static let production = Environment(name: "production")
    public static let development = Environment(name: "development")
    
    public static let current: Environment = {
        #if DEBUG
            return .development
        #else
            return .production
        #endif
    }()
    
    public static var isRelease: Bool { Environment.current == .production }
}
