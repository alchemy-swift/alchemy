fileprivate struct TwilioProvider: ChannelProvider {
    typealias C = SMSChannel

    let accountSID: String
    let authToken: String
    let fromNumber: String
    let baseURL: String
    
    func send(message: SMSMessage, to device: SMSDevice) async throws {
        _ = try await Http
            .withBasicAuth(username: accountSID, password: authToken)
            .withForm([
                "From": message.from ?? fromNumber,
                "Body": message.text,
                "To": device.number
            ])
            .post("\(baseURL)/Accounts/\(accountSID)/Messages.json")
    }
}

extension SMSMessenger {
    public static func twilio(accountSID: String, authToken: String, fromNumber: String, baseURL: String = "https://api.twilio.com/2010-04-01") -> SMSMessenger {
        Messenger(provider: TwilioProvider(accountSID: accountSID, authToken: authToken, fromNumber: fromNumber, baseURL: baseURL))
    }
}
