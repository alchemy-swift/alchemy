import Foundation

/// Represents a frequency that occurs at a `rate` and may have specific requirements for when it
/// should start running, such as "every day at 9:30 am".
public protocol Frequency {
    /// The interval at which this `Frequency` is repeated.
    var rate: TimeAmount { get }
    
    /// An interval until the next time this frequency can begin.
    ///
    /// - Returns: a `TimeAmount` representing the interval between now and when this frequency's
    ///            start time will next occur.
    func timeUntilNext() -> TimeAmount
}

// MARK: - TimeUnits

/// A unit of time.
public protocol TimeUnit {
    /// Returns a `TimeAmount` for a measure of time with this unit.
    ///
    /// - Parameter value: the measurement of time.
    /// - Returns an interval representing `value` units of this `TimeUnit`.
    static func time(_ value: Int64) -> TimeAmount
}

/// A week of time.
public struct WeekUnit: TimeUnit {
    // MARK: TimeUnit
    
    public static func time(_ value: Int64) -> TimeAmount { .hours(value * 24 * 7) }
}

/// A day of time.
public struct DayUnit: TimeUnit {
    // MARK: TimeUnit
    
    public static func time(_ value: Int64) -> TimeAmount { .hours(value * 24) }
}

/// An hour of time.
public struct HourUnit: TimeUnit {
    // MARK: TimeUnit
    
    public static func time(_ value: Int64) -> TimeAmount { .hours(value) }
}

/// A minute of time.
public struct MinuteUnit: TimeUnit {
    // MARK: TimeUnit
    
    public static func time(_ value: Int64) -> TimeAmount { .minutes(value) }
}

/// A second of time.
public struct SecondUnit: TimeUnit {
    // MARK: TimeUnit
    
    public static func time(_ value: Int64) -> TimeAmount { .seconds(value) }
}

// MARK: - Frequencies

/// A generic frequency for handling amounts of time.
public struct FrequencyTyped<T: TimeUnit>: Frequency {
    /// The frequency at which this work should be repeated.
    let value: Int
    
    /// The day this frequency should start on.
    fileprivate let startDay: Weekday?
    
    /// The hour this frequency should start on.
    fileprivate let startHr: Int?
    
    /// The minute this frequency should start on.
    fileprivate let startMin: Int?
    
    /// The second this frequency should start on.
    fileprivate let startSec: Int?
    
    /// Create a frequency with the given components.
    ///
    /// - Parameters:
    ///   - value: the value of the unit of time between frequencies.
    ///   - day: the start day of this frequency.
    ///   - hr: the start hour of this frequency.
    ///   - min: the start minute of this frequency.
    ///   - sec: the start second of this frequency.
    fileprivate init(
        value: Int,
        day: Weekday? = nil,
        hr: Int? = nil,
        min: Int? = nil,
        sec: Int? = nil
    ) {
        self.value = value
        self.startDay = day
        self.startHr = hr
        self.startMin = min
        self.startSec = sec
    }
    
    // MARK: Frequency
    
    public var rate: TimeAmount {
        T.time(Int64(self.value))
    }
    
    public func timeUntilNext() -> TimeAmount {
        let now = Date()
        let calendar = Calendar.current
        let components = DateComponents(
            calendar: calendar,
            hour: self.startHr,
            minute: self.startMin,
            second: self.startSec,
            weekday: self.startDay?.rawValue
        )
        let nextTime = calendar
            .nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
        let interval = Int64(nextTime.timeIntervalSince(now) * 1000)
        return .milliseconds(interval)
    }
}

/// A frequency measured in a number of seconds.
public typealias Seconds = FrequencyTyped<SecondUnit>

/// A frequency measured in a number of minutes.
public typealias Minutes = FrequencyTyped<MinuteUnit>
extension Minutes {
    /// When this frequency should first take place.
    ///
    /// - Parameter sec: a second of a minute (0-59).
    /// - Returns: a minutely frequency that first takes place at the given component.
    public func at(sec: Int? = nil) -> Minutes {
        Minutes(value: self.value, sec: sec)
    }
}

/// A frequency measured in a number of hours.
public typealias Hours = FrequencyTyped<HourUnit>
extension Hours {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - min: a minute of an hour (0-59).
    ///   - sec: a second of a minute (0-59).
    /// - Returns: an hourly frequency that first takes place at the given components.
    public func at(min: Int? = nil, sec: Int? = nil) -> Hours {
        Hours(value: self.value, min: min, sec: sec)
    }
}

/// A frequency measured in a number of days.
public typealias Days = FrequencyTyped<DayUnit>
extension Days {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - hr: an hour of the day (0-23).
    ///   - min: a minute of an hour (0-59).
    ///   - sec: a second of a minute (0-59).
    /// - Returns: a daily frequency that first takes place at the given components.
    public func at(hr: Int? = nil, min: Int? = nil, sec: Int? = nil) -> Days {
        Days(value: self.value, min: min, sec: sec)
    }
}

/// A frequency measured in a number of weeks.
public typealias Weeks = FrequencyTyped<WeekUnit>
extension Weeks {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - day: a day of the week.
    ///   - hr: an hour of the day (0-23).
    ///   - min: a minute of an hour (0-59).
    ///   - sec: a second of a minute (0-59).
    /// - Returns: a weekly frequency that first takes place at the given components.
    public func at(_ day: Weekday? = nil, hr: Int? = nil, min: Int? = nil, sec: Int? = nil) -> Weeks {
        Weeks(value: self.value, day: day, hr: hr, min: min, sec: sec)
    }
}

// MARK: - Misc

/// A day of the week.
public enum Weekday: Int {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

extension Int {
    /// A frequence of weeks.
    public var weeks: Weeks { Weeks(value: self, hr: 0, min: 0, sec: 0) }
    
    /// A frequence of days.
    public var days: Days { Days(value: self, hr: 0, min: 0, sec: 0) }
    
    /// A frequence of hours.
    public var hours: Hours { Hours(value: self, min: 0, sec: 0) }
    
    /// A frequence of minutes.
    public var minutes: Minutes { Minutes(value: self, sec: 0) }
    
    /// A frequence of seconds.
    public var seconds: Seconds { Seconds(value: self) }
}
