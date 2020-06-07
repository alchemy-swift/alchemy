import Fusion
import NIO

/// Schedules `Job`s at recurring intervals, like a cron.
///
/// Usage:
/// ```swift
/// self.scheduler
///     .every(1.days.at(hr: 12), run: UpdateQueries())
///     .every(1.days.at(hr: 9, min: 27, sec: 43), run: SyncSubscriptions())
///     .every(1.minutes.at(sec: 30), run: RunQueries())
///     .every(1.minutes, run: CheckAlerts())
/// ```
public struct Scheduler {
    /// The loop on which Job scheduling will be done. Note that the
    /// actual Jobs will be run on `EventLoop`s dequeued from the
    /// application's `MultiThreadedEventLoopGroup`.
    let scheduleLoop: EventLoop
    
    /// Schedules a `Job` at a recurring interval.
    ///
    /// - Parameters:
    ///   - frequency: The frequency at which this `Job` should be
    ///     run. See `Frequency`.
    ///   - job: The `Job` to schedule.
    /// - Returns: This `Scheduler` with which more `Job`s can be
    ///   scheduled.
    @discardableResult
    public func every<J: Job>(_ frequency: Frequency, run job: J) -> Scheduler {
        /// A single loop will do all the scheduling for now.
        self.scheduleLoop
            .scheduleRepeatedTask(
                initialDelay: frequency.timeUntilNext(),
                delay: frequency.rate
            ) { repeatedTask in
                Log.info("[Scheduler] starting Job `\(name(of: J.self))`.")
                // For now, never cancel the task.
                _ = Services.eventLoopGroup.next()
                    .flatSubmit(job.run)
                    .map { Log.info("[Scheduler] finished Job `\(name(of: J.self))`.") }
            }
        
        return self
    }
    
    public static var factory: (Container) throws -> Scheduler = { _ in
        Scheduler(scheduleLoop: Loop.current)
    }
}
