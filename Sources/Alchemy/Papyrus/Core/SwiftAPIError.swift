public struct SwiftAPIError: Error, CustomStringConvertible {
    public let message: String
    public var description: String { "[SwiftAPIError] \(self.message)" }
    
    public init(message: String) {
        self.message = message
    }
}
