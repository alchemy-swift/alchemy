import NIOConcurrencyHelpers

/// Storage for `Job` decoding behavior.
struct JobRegistry {
    /// Stored decoding behavior for jobs.
    static var creators: [String: (JobData) async throws -> Job] = [:]
    private static let lock = NIOLock()
    
    /// Register a job to cache its decoding behavior.
    static func register(_ jobType: Job.Type) {
        lock.withLock {
            if creators[jobType.name] == nil {
                creators[jobType.name] = jobType.init
            }
        }
    }

    /// Deregister all registered `Job`s.
    static func reset() {
        lock.withLock { creators = [:] }
    }

    /// Decode a job from the given job data.
    static func createJob(from jobData: JobData) async throws -> Job {
        guard let creator = lock.withLock({ creators[jobData.jobName] }) else {
            Log.warning("Unknown job of type '\(jobData.jobName)'. Please register it in your Queues config or with `app.registerJob(\(jobData.jobName).self)`.")
            throw JobError.unknownType
        }

        do {
            return try await creator(jobData)
        } catch {
            Log.error("Error decoding job named \(jobData.jobName): \(error).")
            throw error
        }
    }
}
