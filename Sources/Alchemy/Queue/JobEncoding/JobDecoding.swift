struct JobDecoding {
    private typealias JobDecoder = (JobData) throws -> Job
    
    private static var decoders: [String: JobDecoder] = [:]
    
    static func register<J: Job>(_ type: J.Type) {
        self.decoders[J.name] = { try J(jsonString: $0.json) }
    }
    
    static func decode(_ jobData: JobData) throws -> Job {
        guard let decoder = JobDecoding.decoders[jobData.jobName] else {
            throw JobError("Unknown job of type '\(jobData.jobName)'. Please register it via `app.registerJob(MyJob.self)`.")
        }
        
        return try decoder(jobData)
    }
}
