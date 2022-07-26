// MARK: Aliases

public var Slack: SlackMessenger { .default }
public func Slack(_ id: SlackMessenger.Identifier) -> SlackMessenger { .id(id) }

// MARK: SMSMessenger

public typealias SlackMessenger = Messenger<SlackChannel>

extension SlackMessenger {
    public func send(_ message: SlackMessage, toHook: String) async throws {
        try await send(message, to: SlackHook(url: toHook))
    }
    
    public func send(_ message: SlackMessage, to receiver: SlackReceiver) async throws {
        try await send(message, to: receiver.hook)
    }
}

// MARK: Config + SMS

extension AnyChannelConfig where Self == SlackMessenger.ChannelConfig {
    public static func slack(_ messengers: [SlackMessenger.Identifier: SlackMessenger]) -> AnyChannelConfig {
        SlackMessenger.ChannelConfig(messengers: messengers)
    }
}
