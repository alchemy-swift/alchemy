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

extension Notification where Self: Job2, Self: Codable, Self.N: Codable {
    func enqueue(notifiable: N, on queue: Queue) async throws {
        let payload = NotificationJobPayload(notif: self, receiver: notifiable)
        let data = try JSONEncoder().encode(payload)
    }
    
    static func dequeue(data: JobData) async throws {
        let payload = try JSONDecoder().decode(NotificationJobPayload<Self, N>.self, from: Data(data.json.utf8))
        try await payload.notif.send(to: payload.receiver)
    }
}
