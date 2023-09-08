extension Job {
    public func handle() async throws {
        try await handle(context: .fake)
    }
}

extension JobContext {
    public static var fake: JobContext {
        JobContext(
            queue: .memory,
            channel: Queue.defaultChannel,
            jobData: JobData(
                id: UUID().uuidString,
                payload: Data(),
                jobName: "foo",
                channel: Queue.defaultChannel,
                attempts: 0,
                recoveryStrategy: .none,
                backoff: .zero,
                backoffUntil: nil
            )
        )
    }
}
