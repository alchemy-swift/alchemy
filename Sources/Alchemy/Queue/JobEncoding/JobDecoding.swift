/// Storage for `Job` decoding behavior.
struct JobDecoding {
    @Locked static var registeredJobs: [Job.Type] = []
    
    /// Stored decoding behavior for jobs.
    @Locked private static var decoders: [String: (JobData) throws -> Job] = [:]
    
    /// Register a job to cache its decoding behavior.
    ///
    /// - Parameter type: A job type.
    static func register<J: Job>(_ type: J.Type) {
        decoders[J.name] = { try J(jsonString: $0.json) }
        registeredJobs.append(type)
    }
    
    /// Indicates if the given type is already registered.
    ///
    /// - Parameter type: A job type.
    /// - Returns: Whether this job type is already registered.
    static func isRegistered<J: Job>(_ type: J.Type) -> Bool {
        decoders[J.name] != nil
    }
    
    /// Decode a job from the given job data.
    ///
    /// - Parameter jobData: The job data to decode.
    /// - Throws: Any errors encountered while decoding the job.
    /// - Returns: The decoded job.
    static func decode(_ jobData: JobData) throws -> Job {
        guard let decoder = JobDecoding.decoders[jobData.jobName] else {
            Log.warning("Unknown job of type '\(jobData.jobName)'. Please register it via `app.registerJob(MyJob.self)`.")
            throw JobError.unknownType
        }
        
        do {
            return try decoder(jobData)
        } catch {
            Log.error("[Queue] error decoding job named \(jobData.jobName). Error was: \(error).")
            throw error
        }
    }
    
    static func reset() {
        decoders = [:]
        registeredJobs = []
    }
}
