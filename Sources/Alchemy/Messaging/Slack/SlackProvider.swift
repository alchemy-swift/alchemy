struct SlackProvider: ChannelProvider {
    typealias C = SlackChannel
    
    func send(message: SlackMessage, to: SlackReceiver) async throws {
        // send
    }
}

extension SlackMessenger {
    public static func hook(_ hook: String) -> SlackMessenger {
        Messenger(provider: SlackProvider())
    }
}
