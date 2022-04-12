/*
 Shared Logic
 1. Destination
 2. Content
 3. Sender
 */

/*
 Notification
 1. data
 2. message(s)
    1. content
    2. receiver
    3. channel
 3. queuable
 */

// MARK: Example

struct Tester {
    func main() async throws {
        
        /*
         APIs
         Type Based
         1. user.sendSMS("Hello!") // Would require User: SMSNotifiable
         2. user.send(MyNotification()) // would need User: Notifiable and `send(to recipient: GenericType)` in `MyNotification`
         
         Problem; some receivers may be concrete types (User) some may be protocols (SMSNotifiable). Hard to add generic methods for protocols; can do associatedtype R: Protocol ?
         
         One Off
         1. SMS.send("Hello!", to: "8609902262") // simple
         2. SMSMessage("Hello there!").send(to: "8609902262") // Would require Generic Receiver / Sender type embedded in SMSMessage
         3. MyNotification(user: User).send() // simple, esp with Job. Makes it easier to encode payload too.
         4. MyNotification().send(to: user) // Would require Generic Receiver / Sender type embedded in SMSMessage
         */
        
        /*
         Sender
         Message
         Receiver
         
         1. user.sendSMS("ddd")
         - user needs receiver data (via protocol to add method)
         2. user.send(MyNotification())
         - User needs to know it can send notifications (protocol)
         - User needs to know what notifications it can send (impossible(?) constraint)
         - MyNotification needs Receiver type embedded (PAT)
         3. SMS.send(...)
         - Sender needs Message and Reciever embedded
         4. SMSMessage().send(to: ...)
         - Message needs receiver type embedded (PAT)
         5. SMSMessage().send()
         - Message needs receiver data embedded (data)
         6. MyNotification().send(to: ...)
         - Message needs receiver type embedded (PAT)
         7. MyNotification().send()
         - Message needs receiver data embedded (data)
         */
        
        let user = User(name: "Josh", phone: "8609902262", email: "josh@withapollo.com")
        try await user.send(SMSMessage(text: "yo"))
        try await user.sendSMS("Welcome to Apollo!!!")
        try await user.sendEmail("<p> Hello from Apollo! </p>")
        try await WelcomeText(user: user).send()
    }
}

struct WelcomeText {
    let user: User
    
    func send() async throws {
        try await user.sendSMS("Welcome to Apollo, \(user.name)!")
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

/*
 For Each Channel
 - Sender
 - Message
 - Receiver
 - receiver.send(Message(...), via: Sender)
 - receiver.sendChannel(..., via: Sender)
 - sender.send(Message(), to: Receiver)
 
 Notification
 - Might have multiple channels (aka multiple messages)
 - can't do notifiable.send(MyNotification()) generically without flagging user as something that can handle MyNotification. Lose this 1 API.
 
 What shared logic can generics solve with notifications?
 1. All notifications can be send (however need typesafety, so end up with single protocol for each)
 2. Protocols allow free functions, at the expense of associated types
 */


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

struct SMSMessage {
    let text: String
}

protocol SMSReceiver {
    var phone: String { get }
}

struct SMSSender {
    func send(message: SMSMessage, to receiver: SMSReceiver) async throws {
        // send it
    }
}

extension SMSReceiver {
    func send(_ sms: SMSMessage) async throws {
        
    }
    
    func sendSMS(_ message: String) async throws {
        try await SMSSender().send(message: SMSMessage(text: message), to: self)
    }
}
