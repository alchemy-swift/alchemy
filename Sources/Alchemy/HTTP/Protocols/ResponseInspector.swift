import NIOHTTP1

public protocol ResponseInspector: HTTPInspector {
    var status: HTTPResponseStatus { get }
}

extension ResponseInspector {
    
    // MARK: Status Information

    public var isOk: Bool { status == .ok }
    public var isSuccessful: Bool { (200...299).contains(status.code) }
    public var isFailed: Bool { isClientError || isServerError }
    public var isClientError: Bool { (400...499).contains(status.code) }
    public var isServerError: Bool { (500...599).contains(status.code) }
}
