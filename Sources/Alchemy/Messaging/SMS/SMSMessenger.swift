// MARK: Aliases

public var SMS: SMSMessenger { .default }
public func SMS(_ id: SMSMessenger.Identifier) -> SMSMessenger { .id(id) }

// MARK: SMSMessenger

public typealias SMSMessenger = Messenger<SMSChannel>

extension SMSMessenger {
    private struct _OneOffReceiver: SMSReceiver {
        let phone: String
    }
    
    public func send(message: SMSMessage, phone: String) async throws {
        try await send(message: message, receiver: _OneOffReceiver(phone: phone))
    }
}

extension Messenger.Identifier where C == SMSChannel {
    static let foo: Self = "foo"
}
