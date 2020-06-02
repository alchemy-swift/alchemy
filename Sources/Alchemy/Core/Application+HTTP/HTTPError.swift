import NIOHTTP1

public struct HTTPError: Error {
    public let status: HTTPResponseStatus
    public let message: String?
    
    public init(_ status: HTTPResponseStatus, message: String? = nil) {
        self.status = status
        self.message = message
    }
}
