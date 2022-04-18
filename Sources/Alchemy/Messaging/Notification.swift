public protocol Notification {
    associatedtype N: Notifiable
    
    func send(to notifiable: N) async throws
}

public protocol Notifiable {}

extension Notifiable {
    public func notify<N: Notification>(_ message: N) async throws where N.N == Self {
        try await message.send(to: self)
    }
}

extension Array: Notifiable where Element: Notifiable {}
