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
    public func schedule<J: Job>(_ job: J, every frequency: Frequency) -> Scheduler {
        let secondsUntilFirst = frequency.initialDelay.nanoseconds / 1000000000
        let seconds = secondsUntilFirst % 60
        let minutes = (secondsUntilFirst / 60) % 60
        let hours = (secondsUntilFirst / 60 / 60) % 24
        Log.info("`\(name(of: J.self))` was scheduled. The first one will run in \(hours) hrs \(minutes) mins \(seconds) secs.")
        /// A single loop will do all the scheduling for now.
        self.scheduleLoop
            .scheduleRepeatedTask(initialDelay: frequency.initialDelay, delay: frequency.time) { repeatedTask in
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
    /// The frequency @ which this should be repeated.
    var time: TimeAmount { get }
    
    /// The delay (from now) that the first of these Jobs should be scheduled.
    ///
    /// i.e. if the `Frequency` is hourly on the hour and it's 1:35, this will be equivalent to
    /// `.minutes(25)`.
    var initialDelay: TimeAmount { get }
}

extension Frequency {
    func timeUntilNext(day: Int? = nil, hr: Int? = nil, min: Int? = nil, sec: Int? = nil) -> TimeAmount {
        let now = Date()
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, day: day, hour: hr, minute: min, second: sec)
        let nextTime = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
        let interval = Int64(nextTime.timeIntervalSince(now) * 1000)
        return .milliseconds(interval)
    }
}

public struct DayFrequency: Frequency {
    let value: Int64
    
    let hr: Int
    let min: Int
    let sec: Int

    public var time: TimeAmount { .hours(value * 24) }
    
    public var initialDelay: TimeAmount {
        self.timeUntilNext(hr: self.hr, min: self.min, sec: self.sec)
    }
    
    public func at(hr: Int = 0, min: Int = 0, sec: Int = 0) -> DayFrequency {
        .init(value: self.value, hr: hr, min: min, sec: sec)
    }
}

public struct HourFrequency: Frequency {
    let value: Int64
    
    let min: Int
    let sec: Int
    
    public var time: TimeAmount { .hours(value) }
    
    public var initialDelay: TimeAmount {
        self.timeUntilNext(min: self.min, sec: self.sec)
    }
    
    public func at(min: Int = 0, sec: Int = 0) -> HourFrequency {
        .init(value: self.value, min: min, sec: sec)
    }
}

public struct MinuteFrequency: Frequency {
    let value: Int64
    
    let sec: Int
    
    public var time: TimeAmount { .minutes(value) }
    
    public var initialDelay: TimeAmount {
        self.timeUntilNext(sec: self.sec)
    }
    
    public func at(sec: Int = 0) -> MinuteFrequency {
        .init(value: self.value, sec: sec)
    }
}

extension Int {
    public var days: DayFrequency { DayFrequency(value: Int64(self), hr: 0, min: 0, sec: 0) }
    public var hours: HourFrequency { HourFrequency(value: Int64(self), min: 0, sec: 0) }
    public var minutes: MinuteFrequency { MinuteFrequency(value: Int64(self), sec: 0) }
}
