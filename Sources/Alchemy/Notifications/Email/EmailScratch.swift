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
