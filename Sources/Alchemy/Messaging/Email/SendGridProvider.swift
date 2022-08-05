private struct SendgridProvider: ChannelProvider {
    typealias C = EmailChannel

    let key: String
    let sender: String
    
    func send(message: EmailMessage, to recipient: EmailRecipient) async throws {
        _ = try await Http
            .withToken(key)
            .withJSON([
                "personalizations": [
                    [
                        "to": [
                            ["email": recipient.email]
                        ],
                        "subject": message.subject,
                    ]
                ],
                "from": [
                    "email": message.from ?? sender
                ],
                "content": [
                    [
                        "type": "text/plain",
                        "value": message.content
                    ],
                ]
            ])
            .post("https://api.sendgrid.com/v3/mail/send")
            .validateSuccessful()
    }
}

extension EmailMessenger {
    public static func sendGrid(key: String, sender: String) -> EmailMessenger {
        Messenger(provider: SendgridProvider(key: key, sender: sender))
    }
}
