public struct EndpointMethod: Equatable {
    public static let delete = EndpointMethod("DELETE")
    public static let get = EndpointMethod("GET")
    public static let patch = EndpointMethod("PATCH")
    public static let post = EndpointMethod("POST")
    public static let put = EndpointMethod("PUT")
    
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
