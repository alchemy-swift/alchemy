import Cron
import NIOCore

/// Used to help build schedule frequencies for scheduled tasks.
public final class Frequency {
    /// A day of the week.
    public enum DayOfWeek: Int, ExpressibleByIntegerLiteral {
        /// Sunday
        case sun = 0
        /// Monday
        case mon = 1
        /// Tuesday
        case tue = 2
        /// Wednesday
        case wed = 3
        /// Thursday
        case thu = 4
        /// Friday
        case fri = 5
        /// Saturday
        case sat = 6

        public init(integerLiteral value: Int) {
            self = DayOfWeek(rawValue: value) ?? .sun
        }
    }

    /// A month of the year.
    public enum Month: Int, ExpressibleByIntegerLiteral {
        /// January
        case jan = 1
        /// February
        case feb = 2
        /// March
        case mar = 3
        /// April
        case apr = 4
        /// May
        case may = 5
        /// June
        case jun = 6
        /// July
        case jul = 7
        /// August
        case aug = 8
        /// September
        case sep = 9
        /// October
        case oct = 10
        /// November
        case nov = 11
        /// December
        case dec = 12

        public init(integerLiteral value: Int) {
            self = Month(rawValue: value) ?? .jan
        }
    }

    /// A cron expression that represents this frequency.
    ///
    /// {seconds} {minutes} {hour} {day of month} {month} {day of week} {year}
    var cron = try! DatePattern("* * * * * * *")

    /// The time amount until the next interval, if there is one.
    func timeUntilNext() -> TimeAmount? {
        guard let next = cron.next(), let nextDate = next.date else {
            return nil
        }

        var delay = Int64(nextDate.timeIntervalSinceNow * 1000)
        
        // Occasionally the Cron library returns the `next()` as fractions of a
        // millisecond before or after now. If the delay is 0, get the
        // subsequent date and use that instead.
        if delay == 0 {
            let newDate = cron.next(next)?.date ?? Date().addingTimeInterval(1)
            delay = Int64(newDate.timeIntervalSinceNow * 1000)
        }
        
        return .milliseconds(delay)
    }

    // MARK: Builders

    /// Run this task yearly.
    ///
    /// - Parameters:
    ///   - month: The month to run.
    ///   - day: The day of the month to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func everyYear(month: Month = .jan, day: Int = 1, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        cron("\(sec) \(min) \(hr) \(min) \(day) \(month.rawValue) * *")
    }

    /// Run this task monthly.
    ///
    /// - Parameters:
    ///   - day: The day of the month to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func everyMonth(day: Int = 1, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        cron("\(sec) \(min) \(hr) \(day) * * *")
    }

    /// Run this task weekly.
    ///
    /// - Parameters:
    ///   - day: The day of the week to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func everyWeek(day: DayOfWeek = .sun, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        cron("\(sec) \(min) \(hr) * * \(day.rawValue) *")
    }

    /// Run this task daily.
    ///
    /// - Parameters:
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func everyDay(hr: Int = 0, min: Int = 0, sec: Int = 0) {
        cron("\(sec) \(min) \(hr) * * * *")
    }

    /// Run this task every hour.
    ///
    /// - Parameters:
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func everyHour(min: Int = 0, sec: Int = 0) {
        cron("\(sec) \(min) * * * * *")
    }

    /// Run this task every minute.
    ///
    /// - Parameters:
    ///   - sec: The second to run.
    public func everyMinute(sec: Int = 0) {
        cron("\(sec) * * * * * *")
    }

    /// Run this task every second.
    public func everySecond() {
        cron("* * * * * * *")
    }

    /// Run this task according to the given cron expression. Second
    /// and year fields are acceptable.
    ///
    /// This will stop program execution if the expression is invalid.
    ///
    /// - Parameter expression: A cron expression.
    public func cron(_ expression: String) {
        do {
            cron = try DatePattern(expression)
        } catch {
            preconditionFailure("Error parsing cron expression '\(cron)': \(error).")
        }
    }
}
