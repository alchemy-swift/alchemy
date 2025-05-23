import AsyncAlgorithms

actor QueueWorker: Service {
    let queue: Queue
    var channels: [String]
    var pollRate: Duration
    var untilEmpty: Bool

    init(queue: Queue, channels: [String], pollRate: Duration, untilEmpty: Bool) {
        self.queue = queue
        self.channels = channels
        self.pollRate = pollRate
        self.untilEmpty = untilEmpty
    }

    private var timer: some AsyncSequence {
        AsyncTimerSequence(interval: pollRate, clock: ContinuousClock())
            .cancelOnGracefulShutdown()
    }

    func run() async throws {
        // 0. run immediately - `AsyncTimerSequence` waits one `interval` before
        //    firing the first time.
        try await runNext()

        // 1. then run after every interval
        for try await _ in timer {
            try await runNext()
        }
    }

    fileprivate func runNext() async throws {
        do {
            guard var jobData = try await queue.dequeue(from: channels) else {
                return
            }

            Log.debug("Dequeued job \(jobData.jobName) from queue \(jobData.channel)")
            try await execute(&jobData)
            if untilEmpty {
                try await runNext()
            }
        } catch {
            Log.error("Error running job from `\(channels)`. \(error)")
            throw error
        }
    }

    private func execute(_ jobData: inout JobData) async throws {
        var job: Job?
        do {
            jobData.attempts += 1
            job = try await Jobs.createJob(from: jobData)
            let context = JobContext(queue: queue, channel: jobData.channel, jobData: jobData)
            try await job!.handle(context: context)
            try await success(job: job!, jobData: jobData)
        } catch where jobData.canRetry {
            job?.failed(error: error)
            try await retry(jobData: &jobData)
        } catch JobError.unknownJob(let name) {
            let error = JobError.unknownJob(name)
            // So that an old worker won't fail new, unrecognized jobs.
            try await retry(jobData: &jobData, ignoreAttempt: true)
            job?.failed(error: error)
            throw error
        } catch {
            try await queue.complete(jobData, outcome: .failed)
            job?.finished(result: .failure(error))
            job?.failed(error: error)
        }
    }

    private func success(job: Job, jobData: JobData) async throws {
        try await queue.complete(jobData, outcome: .success)
        job.finished(result: .success(()))
    }

    private func retry(jobData: inout JobData, ignoreAttempt: Bool = false) async throws {
        if ignoreAttempt { jobData.attempts -= 1 }
        jobData.backoffUntil = jobData.nextRetryDate
        try await queue.complete(jobData, outcome: .retry)
    }
}

extension Queue {
    /// Start a worker that dequeues and runs jobs from this queue.
    ///
    /// - Parameters:
    ///   - channels: The channels this worker should monitor for
    ///     work. Defaults to `Queue.defaultChannel`.
    ///   - pollRate: The rate at which this worker should poll the
    ///     queue for new work. Defaults to `Queue.defaultPollRate`.
    ///   - untilEmpty: If true, workers will run all available jobs before
    ///     waiting to poll the queue again.
    public func startWorker(for channels: [String] = [Queue.defaultChannel],
                            pollRate: Duration = .seconds(1),
                            untilEmpty: Bool = true) {
        workers += 1
        Life.addService(
            QueueWorker(
                queue: self,
                channels: channels,
                pollRate: pollRate,
                untilEmpty: untilEmpty
            )
        )
    }
}
