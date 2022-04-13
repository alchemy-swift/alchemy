// MARK: Types

public protocol Message {
    associatedtype R: Receiver
    associatedtype Sender: Service
    
    func send(to receiver: R, via sender: Sender) async throws
}

extension Message {
    public func send(to receiver: R, via sender: Sender = .default) async throws {
        try await send(to: receiver, via: sender)
    }
}

public protocol Notification {
    associatedtype R: Receiver
    
    func send(to receiver: R) async throws
}

public protocol Receiver {}
extension Receiver {
    public func send<M: Message>(_ message: M, via sender: M.Sender = .default) async throws where M.R == Self {}
    public func send<N: Notification>(_ message: N) async throws where N.R == Self {}
}

extension Array: Receiver where Element: Receiver {}
