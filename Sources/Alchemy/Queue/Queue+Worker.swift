extension Queue {
    /// Start a worker that dequeues and runs jobs from this queue.
    ///
    /// - Parameters:
    ///   - channels: The channels this worker should monitor for
    ///     work. Defaults to `Queue.defaultChannel`.
    ///   - pollRate: The rate at which this worker should poll the
    ///     queue for new work. Defaults to `Queue.defaultPollRate`.
    ///   - eventLoop: The loop this worker will run on. Defaults to
    ///     your apps next available loop.
    public func startWorker(for channels: [String] = [Queue.defaultChannel], pollRate: TimeAmount = Queue.defaultPollRate, on eventLoop: EventLoop = Loop.group.next()) {
        let loopId = ObjectIdentifier(eventLoop).debugDescription.dropLast().suffix(6)
        Log.info("[Queue] starting worker \(loopId)")
        eventLoop.wrapAsync { try await self.runNext(from: channels) }
            .whenComplete { _ in
                // Run check again in the `pollRate`.
                eventLoop.scheduleTask(in: pollRate) {
                    self.startWorker(for: channels, pollRate: pollRate, on: eventLoop)
                }
            }
    }
    
    func runNext(from channels: [String]) async throws {
        do {
            guard let jobData = try await dequeue(from: channels) else {
                return
            }
            
            Log.debug("[Queue] dequeued job \(jobData.jobName) from queue \(jobData.channel)")
            try await execute(jobData)
            try await runNext(from: channels)
        } catch {
            Log.error("[Queue] error dequeueing job from `\(channels)`. \(error)")
            throw error
        }
    }
    
    /// Dequeue the next job from a given set of channels, ordered by
    /// priority.
    ///
    /// - Parameter channels: The channels to dequeue from.
    /// - Returns: A dequeued `Job`, if there is one.
    func dequeue(from channels: [String]) async throws -> JobData? {
        guard let channel = channels.first else {
            return nil
        }
        
        if let job = try await driver.dequeue(from: channel) {
            return job
        } else {
            return try await dequeue(from: Array(channels.dropFirst()))
        }
    }
    
    private func execute(_ jobData: JobData) async throws {
        var jobData = jobData
        jobData.attempts += 1
        
        func retry(ignoreAttempt: Bool = false) async throws {
            if ignoreAttempt { jobData.attempts -= 1 }
            jobData.backoffUntil = jobData.nextRetryDate()
            try await driver.complete(jobData, outcome: .retry)
        }
        
        var job: Job?
        do {
            job = try JobDecoding.decode(jobData)
            try await job?.run()
            job?.finished(result: .success(()))
            try await driver.complete(jobData, outcome: .success)
        } catch where jobData.canRetry {
            try await retry()
        } catch where (error as? JobError) == JobError.unknownType {
            // So that an old worker won't fail new jobs.
            try await retry(ignoreAttempt: true)
        } catch {
            job?.finished(result: .failure(error))
            try await driver.complete(jobData, outcome: .failed)
        }
    }
}
