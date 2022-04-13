/*
 Up Next
 1. Queueable
 2. Implement Required
    1. Text
    2. Email
    3. APNS
    4. Database
 3. Implement not required
 
 Bonus
 5. Slack
 */

import Foundation
import Papyrus

// MARK: Example

struct Tester {
    func main() async throws {
        let user = User(name: "Josh", phone: "8609902262", email: "josh@withapollo.com")
        try await user.send(SMSMessage(text: "yo"), via: .default)
        try await SMSMessage(text: "yo").send(to: user, via: .default)
        try await user.send(sms: "Welcome to Apollo!!!", via: .default)
        try await user.sendEmail("<p> Hello from Apollo! </p>")
        try await SMS.send(SMSMessage(text: "yo"), to: user)
        try await SMS.send("yo", to: "8609902262")
        try await WelcomeText().send(to: user)
        try await NewReward().send(to: user)
        try await DeploymentComplete().send(to: [user])
        
        // Wishlist
        try await user.send(WelcomeText())
        try await user.send(NewReward())
        try await [user].send(DeploymentComplete())
    }
}

/*
 Job v2.0
 1. Each `Job` converts itself to and from `JobData`.
 2. `Codable` `Jobs` automatically conform by encoding / decoding self.
 */

protocol Job2 {
    init(from: JobData) throws
    func enqueue() throws -> JobData
}

struct NotificationJobPayload<Notif: Codable, Receiver: Codable>: Codable {
    let notif: Notif
    let receiver: Receiver
}

extension Notification where Self: Job2, Self: Codable, Self.R: Codable {
    func enqueue(receiver: R, on queue: Queue) async throws {
        let payload = NotificationJobPayload(notif: self, receiver: receiver)
        let data = try JSONEncoder().encode(payload)
    }
    
    static func dequeue(data: JobData) async throws {
        let payload = try JSONDecoder().decode(NotificationJobPayload<Self, R>.self, from: Data(data.json.utf8))
        try await payload.notif.send(to: payload.receiver)
    }
}

struct DeploymentComplete: Notification {
    func send(to users: [User]) async throws {
        for user in users {
            try await user.send(sms: "Deployment complete!")
        }
    }
}

struct NewReward: Notification {
    func send(to user: User) async throws {
        for device in 0...10 {
            try await user.send(sms: "New reward, \(user.name)!")
        }
    }
}

struct WelcomeText: Notification {
    func send(to user: User) async throws {
        try await user.send(sms: "Welcome to Apollo, \(user.name)!")
    }
}

struct User: Model, SMSReceiver, EmailReceiver {
    var id: Int?
    let name: String
    let phone: String
    let email: String
    var token: String { "foo" }
}

// MARK: Types

protocol Message {
    associatedtype R: Receiver
    associatedtype Sender: Service
    
    func send(to receiver: R, via sender: Sender) async throws
}

extension Message {
    func send(to receiver: R, via sender: Sender = .default) async throws {
        try await send(to: receiver, via: sender)
    }
}

protocol Notification {
    associatedtype R: Receiver
    
    func send(to receiver: R) async throws
}

protocol Receiver {}
extension Receiver {
    func send<M: Message>(_ message: M, via sender: M.Sender = .default) async throws where M.R == Self {}
    func send<N: Notification>(_ message: N) async throws where N.R == Self {}
}

extension Array: Receiver where Element: Receiver {}


// MARK: Email

struct EmailMessage {
    let body: String
}

protocol EmailReceiver {
    var email: String { get }
}

struct EmailSender {
    func send(message: EmailMessage, to receiver: EmailReceiver) async throws {
        // send it
    }
}

extension EmailReceiver {
    func send(_ email: EmailMessage) async throws {
        
    }
    
    func sendEmail(_ message: String) async throws {
        
    }
}

// MARK: SMS

struct SMSMessage<R: SMSReceiver>: Message {
    let text: String
    
    func send(to receiver: R, via sender: SMSSender) async throws {
        
    }
}

extension SMSMessage: ExpressibleByStringInterpolation {
    init(stringLiteral value: String) {
        self.init(text: value)
    }
}

protocol SMSReceiver: Receiver {
    var phone: String { get }
}

extension String: SMSReceiver {
    var phone: String { self }
}

var SMS: SMSSender { SMSSender() }
struct SMSSender: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    func send<R: SMSReceiver>(_ message: SMSMessage<R>, to receiver: R) async throws {
        // send it
    }
}

extension SMSReceiver {
    func send(sms: SMSMessage<Self>, via sender: SMSSender = .default) async throws {}
}
