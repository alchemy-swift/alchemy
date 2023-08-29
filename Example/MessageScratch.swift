import Alchemy

/*

 Helpers for sending a payload, to a target, using domain specific logic.

 i.e. send a push notification to a device(s) using APNSwift
 i.e. send an email to an address using Client
 i.e. send a slack message to a slack hook using Client

 A message has:

 1. Payload
 2. Receiver
 3. Handler (often using some service such as HTTPClient or APNSwiftClient)

 Other things:

 1. Should set a clear pattern for custom implementations and add meaningful
    value (boilerplate reduced, auto integration with Alchemy) to those.
 2. Should have a clear way to set defaults (such as default send address) on at 
    least the Payload.
 3. Should have a clear way to set up services required and defaults around
    handling logic (Plugin).
 4. Should be simple to automatically Queue messages vs send in process.
 5. Should be simple to compose messages.
 6. Should be simple to flag types as receivers of messages.
 7. Should be easy to determine what "channel" to send on, i.e. email or push.

 Case 1: send a slack message with Alchemy.
 Case 2: send a text message with a custom driver.
 Case 3: send a letter.

 */

/*

 Shared Logic

 1. Configuration
 2. Queueing
 3. "Handle"

 Becuase they are generic, the function APIs won't be the best.

 */

struct Demo {
    func go() async throws {
        let channels = Channels(channels: [
            .twilio(accountSID: "", authToken: "", fromNumber: "", baseURL: "")
        ])

        print("\(type(of: channels.channels[0]))")
    }

    func notifyAccountLocked(user: User) {

    }

    func verifyPhone(user: User) async throws {

    }
}

var SMS: TwilioChannel {
    Container.resolveAssert()
}

struct Messenger<C: Channel> {
    let provider: C

    init(provider: C) {
        self.provider = provider
    }
}

protocol Channel<Message> {
    associatedtype Message

    func send(message: Message) async throws
    func shutdown() async throws
}

struct Channels {
    let channels: [Messenger]
}

struct SMSMessage {
    let body: String
    let from: String
    let to: String
}

struct TwilioChannel: Channel {
    let accountSID: String
    let authToken: String
    let fromNumber: String
    let baseURL: String

    func send(message: SMSMessage) async throws {
        try await Http.withBasicAuth(username: accountSID, password: authToken)
            .withForm([
                "From": message.from,
                "Body": message.body,
                "To": message.to
            ])
            .post("\(baseURL)/Accounts/\(accountSID)/Messages.json")
            .validateSuccessful()
    }

    func shutdown() async throws {
        //
    }
}

extension Messenger where C == TwilioChannel {
    static func twilio(accountSID: String, authToken: String, fromNumber: String, baseURL: String) -> Self {
        Messenger(provider: TwilioChannel(accountSID: accountSID, authToken: authToken, fromNumber: fromNumber, baseURL: baseURL))
    }
}
