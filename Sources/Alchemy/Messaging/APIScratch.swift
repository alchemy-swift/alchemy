// MARK: Example

struct Tester {
    func main() async throws {
        let user = User(name: "Josh", phone: "8609902262", email: "josh@withapollo.com")
        
        // Messaging
        try await user.send(sms: SMSMessage(text: "yo"), via: .default)
        try await SMSMessage(text: "yo").send(to: user, via: .default)
        try await user.send(sms: "Welcome to Apollo!!!", via: .default)
        try await user.send(email: EmailMessage(subject: "Testing Alchemy", content: "<b> Hello from Apollo! </b>"), via: .default)
        try await SMS.send(SMSMessage(text: "yo"), to: user)
        try await SMS.send("yo", toPhone: "8609902262")
        
        // Notifications
        try await WelcomeText().send(to: user)
        try await NewReward().send(to: user)
        try await DeploymentComplete().send(to: [user])
        try await user.notify(WelcomeText())
        try await user.notify(NewReward())
        try await [user].notify(DeploymentComplete())
    }
}

// MARK: Notifications

struct DeploymentComplete: Notification {
    func send(to users: [User]) async throws {
        for user in users {
            try await user.send(sms: "Deployment complete!")
        }
    }
}

struct NewReward: Notification {
    func send(to user: User) async throws {
        for _ in 0...10 {
            try await user.send(sms: "New reward, \(user.name)!")
        }
    }
}

struct WelcomeText: Notification {
    func send(to user: User) async throws {
        try await user.send(sms: "Welcome to Apollo, \(user.name)!")
    }
}

// MARK: Model

struct User: Model, Notifiable, SMSReceiver, EmailReceiver {
    var id: Int?
    let name: String
    let phone: String
    let email: String
    var token: String { "foo" }
}
