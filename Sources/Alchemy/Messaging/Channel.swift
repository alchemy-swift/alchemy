public protocol Channel {
    static var identifier: String { get }
    
    associatedtype Message
    associatedtype Receiver
}

extension Channel {
    public static var identifier: String {
        name(of: Self.self)
            .lowercased()
            .droppingSuffix("channel")
    }
}

public protocol ChannelProvider {
    associatedtype C: Channel
    
    func send(message: C.Message, to receiver: C.Receiver) async throws
}
