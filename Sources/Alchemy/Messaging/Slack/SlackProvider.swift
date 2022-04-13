struct SlackProvider: ChannelProvider {
    typealias C = SlackChannel
    
    func send(message: SlackMessage, to: SlackReceiver) async throws {
        // send
    }
}

extension SlackMessenger {
    public static func slackHook(_ hook: String, saveInDatabase: Bool = false) -> SlackMessenger {
        Messenger(provider: SlackProvider(), saveInDatabase: saveInDatabase)
    }
}
