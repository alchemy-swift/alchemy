public protocol Channel {
    associatedtype Message
    associatedtype Receiver
}

public protocol ChannelProvider {
    associatedtype C: Channel
    
    func send(message: C.Message, to: C.Receiver) async throws
}
