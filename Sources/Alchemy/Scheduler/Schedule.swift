import Cron
import NIOCore

/// Used to help build schedule frequencies for scheduled tasks.
public final class Schedule {
    private let buildingFinished: (Schedule) -> Void
    private var pattern: DatePattern? = nil {
        didSet {
            if pattern != nil {
                buildingFinished(self)
            }
        }
    }
    
    /// {seconds} {minutes} {hour} {day of month} {month} {day of week} {year}
    var cronExpression: String? {
        pattern?.string
    }
    
    init(_ buildingFinished: @escaping (Schedule) -> Void) {
        self.buildingFinished = buildingFinished
    }
    
    /// Run this task yearly.
    ///
    /// - Parameters:
    ///   - month: The month to run.
    ///   - day: The day of the month to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func yearly(month: Month = .jan, day: Int = 1, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfMonth: "\(day)", month: "\(month.rawValue)")
    }
    
    /// Run this task monthly.
    ///
    /// - Parameters:
    ///   - day: The day of the month to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func monthly(day: Int = 1, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfMonth: "\(day)")
    }
    
    /// Run this task weekly.
    ///
    /// - Parameters:
    ///   - day: The day of the week to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func weekly(day: DayOfWeek = .sun, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfWeek: "\(day.rawValue)")
    }
    
    /// Run this task daily.
    ///
    /// - Parameters:
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func daily(hr: Int = 0, min: Int = 0, sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)", minute: "\(min)", hour: "\(hr)")
    }
    
    /// Run this task every hour.
    ///
    /// - Parameters:
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func hourly(min: Int = 0, sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)", minute: "\(min)", hour: "*")
    }
    
    /// Run this task every minute.
    ///
    /// - Parameters:
    ///   - sec: The second to run.
    public func minutely(sec: Int = 0) {
        pattern = DatePattern(second: "\(sec)")
    }
    
    /// Run this task every second.
    public func secondly() {
        pattern = DatePattern()
    }
    
    
    /// Run this task according to the given cron expression. Second
    /// and year fields are acceptable.
    ///
    /// - Parameter expression: A cron expression.
    public func expression(_ cronExpression: String) {
        pattern = DatePattern(validate: cronExpression)
    }
    
    /// The delay after which this schedule will be run, if it will ever be run.
    func next() -> TimeAmount? {
        guard let next = pattern?.next(), let nextDate = next.date else {
            return nil
        }

        var delay = Int64(nextDate.timeIntervalSinceNow * 1000)
        // Occasionally Cron library returns the `next()` as fractions of a
        // millisecond before or after now. If the delay is 0, get the next
        // date and use that instead.
        if delay == 0 {
            let newDate = pattern?.next(next)?.date ?? Date().addingTimeInterval(1)
            delay = Int64(newDate.timeIntervalSinceNow * 1000)
        }
        
        return .milliseconds(delay)
    }
}

extension DatePattern {
    /// Initialize with a cron expression. This will crash if the
    /// expression is invalid.
    fileprivate init(validate cronExpression: String) {
        do {
            self = try DatePattern(cronExpression)
        } catch {
            fatalError("failed to parse cron expression from \(cronExpression). Error was: \(error).")
        }
    }
    
    /// Initialize with pieces of a cron expression. Each piece
    /// defaults to `*`. This will fatal if a piece of the
    /// expression is invalid.
    fileprivate init(
        second: String = "*",
        minute: String = "*",
        hour: String = "*",
        dayOfMonth: String = "*",
        month: String = "*",
        dayOfWeek: String = "*",
        year: String = "*"
    ) {
        let string = [second, minute, hour, dayOfMonth, month, dayOfWeek, year].joined(separator: " ")
        do {
            self = try DatePattern(string)
        } catch {
            fatalError("failed to parse cron expression from \(string). Error was: \(error).")
        }
    }
}
