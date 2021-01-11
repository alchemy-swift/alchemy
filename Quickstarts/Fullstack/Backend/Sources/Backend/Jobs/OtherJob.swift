import Alchemy

struct OtherJob: Job {
    func run() -> EventLoopFuture<Void> {
        .new() // Filler, this job doesn't do anything.
    }
}
