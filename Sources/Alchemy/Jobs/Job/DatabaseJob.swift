import Foundation

public struct DatabaseJob: Model, PersistedJob {
    public static var tableName: String = "jobs"

    public var id: Int?
    public var name: String
    public var payload: JSONData
    public var attempts: Int // How many times a job has been run
    var reserved: Bool // If a worker is currently processing
    var reservedAt: Date? // When the worker started the process

    init(name: String, payload: Data) {
        self.name = name
        self.payload = JSONData(data: payload)
        self.attempts = 0
        self.reserved = false
    }
}

struct FailedJob: Model {
    var id: Int?
    var name: String
    var payload: JSONData

    init(job: DatabaseJob) {
        self.name = job.name
        self.payload = job.payload
    }
}
