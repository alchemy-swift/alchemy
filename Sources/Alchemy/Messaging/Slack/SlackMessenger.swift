// MARK: Aliases

public var Slack: SlackMessenger { .default }
public func Slack(_ id: SlackMessenger.Identifier) -> SlackMessenger { .id(id) }

// MARK: SMSMessenger

public typealias SlackMessenger = Messenger<SlackChannel>

extension SlackMessenger {
    private struct _OneOffReceiver: SlackReceiver {
        let hook: String
    }
    
    public func send(_ message: SlackMessage, toPhone: String, fromPhone: String? = nil) async throws {
        var copy = message
        copy.from = fromPhone
        try await send(copy, to: _OneOffReceiver(hook: toPhone))
    }
}

// MARK: Config + SMS

extension AnyChannelConfig where Self == SlackMessenger.ChannelConfig {
    public static func slack(_ messengers: [SlackMessenger.Identifier: SlackMessenger]) -> AnyChannelConfig {
        SlackMessenger.ChannelConfig(messengers: messengers)
    }
}
