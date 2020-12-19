import Fusion
import NIO

/// Schedules `Job`s at recurring intervals, like a cron.
///
/// Usage:
/// ```
/// self.scheduler
///     .schedule(UpdateQueries(), every: 1.days.at(hr: 12))
///     .schedule(SyncSubscriptions(), every: 1.days.at(hr: 9, min: 27, sec: 43))
///     .schedule(RunQueries(), every: 1.minutes.at(sec: 30))
///     .schedule(CheckAlerts(), every: 1.minutes.at(sec: 00))
/// ```
public struct Scheduler: SingletonService {
    /// The global `MultiThreadedEventLoopGroup` for scheduling work on.
    @Inject var group: MultiThreadedEventLoopGroup
    
    /// The loop on which Job scheduling will be done. Note that the actual Jobs will be run on
    /// `EventLoop`s dequeued from the application's `MultiThreadedEventLoopGroup`.
    private var scheduleLoop: EventLoop
    
    /// Schedules a `Job` at a recurring interval.
    ///
    /// - Parameters:
    ///   - job: the `Job` to schedule.
    ///   - frequency: the frequency at which this `Job` should be run. See `Frequency` for API.
    /// - Returns: this `Scheduler` with which more `Job`s can be scheduled.
    @discardableResult
    public func schedule<J: Job>(_ job: J, every frequency: Frequency) -> Scheduler {
        /// A single loop will do all the scheduling for now.
        self.scheduleLoop
            .scheduleRepeatedTask(
                initialDelay: frequency.timeUntilNext(),
                delay: frequency.rate
            ) { repeatedTask in
                Log.info("Starting Job `\(name(of: J.self))`.")
                // for now, never cancel the task.
                _ = self.group.next()
                    .flatSubmit(job.run)
                    .map { Log.info("Finished Job `\(name(of: J.self))`.") }
            }
        
        return self
    }
    
    // MARK: SingletonService

    public static func singleton(in container: Container) throws -> Scheduler {
        Scheduler(scheduleLoop: Loop.current)
    }
}
