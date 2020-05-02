struct Environment: Equatable {
    let name: String
    
    static let testing = Environment(name: "testing")
    static let production = Environment(name: "production")
    static let development = Environment(name: "development")
    
    static let current: Environment = {
        #if DEBUG
            print("Dev")
            return .development
        #else
            print("Prod")
            return .production
        #endif
    }()
}
