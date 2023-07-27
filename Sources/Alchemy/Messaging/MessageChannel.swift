public protocol MessageChannel {
    associatedtype Message
    associatedtype Receiver
    
    static var identifier: String { get }
}

extension MessageChannel {
    public static var identifier: String {
        name(of: Self.self)
            .lowercased()
            .droppingSuffix("channel")
    }
}

public protocol MessageChannelProvider {
    associatedtype C: MessageChannel
    
    func send(message: C.Message, to receiver: C.Receiver) async throws
    func shutdown() throws
}

extension MessageChannelProvider {
    public func shutdown() throws {}
}
