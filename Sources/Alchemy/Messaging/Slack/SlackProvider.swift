struct SlackProvider: ChannelProvider {
    typealias C = SlackChannel
    
    func send(message: SlackMessage, to hook: SlackHook) async throws {
        _ = try await Http
            .withJSON(message.payload)
            .post(hook.url)
            .validateSuccessful()
    }
}

fileprivate struct WebhookPayload: Codable {
    let text: String
}

extension SlackMessage {
    fileprivate var payload: WebhookPayload {
        WebhookPayload(text: text)
    }
}

extension SlackMessenger {
    public static var slack: SlackMessenger {
        Messenger(provider: SlackProvider())
    }
}
