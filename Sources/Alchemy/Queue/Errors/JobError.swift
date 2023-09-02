/// An error encountered when interacting with a `Job`.
public struct JobError: Error, Equatable {
    private enum ErrorType: Equatable {
        case unknownJobType
        case general(String)
    }
    
    private let type: ErrorType
    
    private init(type: ErrorType) {
        self.type = type
    }
    
    /// Initialize with a message.
    init(_ message: String) {
        self.init(type: .general(message))
    }
    
    /// Unable to decode a job; it wasn't registered to the app.
    static let unknownType = JobError(type: .unknownJobType)
}
