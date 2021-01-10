import Alchemy

// Jobs are used to run recurring work related to your server.
struct SampleJob: Job {
    func run() -> EventLoopFuture<Void> {
        .new() // Filler, this job doesn't do anything.
    }
}
