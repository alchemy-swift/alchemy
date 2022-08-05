private struct SendgridProvider: ChannelProvider {
    typealias C = EmailChannel

    static let baseUrl = "https://api.sendgrid.com/v3/mail/send"

    let key: String
    let fromEmail: String

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
                    "email": message.from ?? fromEmail
                ],
                "content": [
                    [
                        "type": "text/plain",
                        "value": message.content
                    ],
                ]
            ])
            .post(SendgridProvider.baseUrl)
            .validateSuccessful()
    }
}

extension EmailMessenger {
    public static func sendGrid(key: String, fromEmail: String) -> EmailMessenger {
        Messenger(provider: SendgridProvider(key: key, fromEmail: fromEmail))
    }
}
