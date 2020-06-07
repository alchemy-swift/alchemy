import NIO

/// Fires & forgets recurring work, doesn't use any notion of job storage or driver. Kind of like an internal
/// Cron. Can kill once there's a real datastore backed jobs service.
///
/// ```
/// ` self.scheduler
/// `   .schedule(UpdateQueries(), every: 1.days.at(hr: 12))
/// `   .schedule(SyncSubscriptions(), every: 1.days.at(hr: 9, min: 27, sec: 43))
/// `   .schedule(RunQueries(), every: 1.minutes.at(sec: 30))
/// `   .schedule(CheckAlerts(), every: 1.minutes.at(sec: 00))
/// ```
public struct Scheduler: FactoryService {
    @Inject var group: MultiThreadedEventLoopGroup
    
    /// The loop on which Job scheduling will be done. Note that the actual Jobs will be run on `EventLoop`s
    /// dequeued from the application's `MultiThreadedEventLoopGroup`.
    private var scheduleLoop: EventLoop
    
    @discardableResult
    public func schedule<J: Job>(_ job: J, every schedule: Frequency) -> Scheduler {
        /// A single loop will do all the scheduling for now.
        self.scheduleLoop
            .scheduleRepeatedTask(initialDelay: .seconds(0), delay: schedule.time) { repeatedTask in
                Log.info("Starting Job `\(name(of: J.self))`.")
                // for now, never cancel the task.
                _ = self.group.next()
                    .flatSubmit(job.run)
                    .map { Log.info("Finished Job `\(name(of: J.self))`.") }
            }
        
        return self
    }
    
    public static var factory: (Container) throws -> Scheduler = { _ in
        Scheduler(scheduleLoop: Loop.current)
    }
}

public protocol Frequency {
    var time: TimeAmount { get }
    /// Ignore for now.
    var initialDelay: TimeAmount { get }
}

extension Frequency {
    public var initialDelay: TimeAmount { .seconds(0) }
}

public struct DayFrequency: Frequency {
    let value: Int64
    
    public var time: TimeAmount { .hours(value * 24) }
    
    public func at(hr: Int = 0, min: Int = 0, sec: Int = 0) -> DayFrequency {
        self
    }
}

public struct HourFrequency: Frequency {
    let value: Int64
    public var time: TimeAmount { .hours(value) }
    
    public func at(min: Int = 0, sec: Int = 0) -> HourFrequency {
        self
    }
}

public struct MinuteFrequency: Frequency {
    let value: Int64
    public var time: TimeAmount { .minutes(value) }
    
    public func at(sec: Int = 0) -> MinuteFrequency {
        self
    }
}

extension Int {
    public var days: DayFrequency { DayFrequency(value: Int64(self)) }
    public var hours: HourFrequency { HourFrequency(value: Int64(self)) }
    public var minutes: MinuteFrequency { MinuteFrequency(value: Int64(self)) }
}
