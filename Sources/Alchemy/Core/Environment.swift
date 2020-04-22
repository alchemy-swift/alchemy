struct Environment: Equatable {
    let name: String
    
    static let testing = Environment(name: "testing")
    static let production = Environment(name: "production")
    static let development = Environment(name: "development")
    
    static let current: Environment = {
        /// Load from CommandLine.arguments
        .development
    }()
}
