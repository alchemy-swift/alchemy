import Foundation

/// Represents a frequency that occurs at a `rate` and may have
/// specific requirements for when it should start running,
/// such as "every day at 9:30 am".
public protocol Frequency {
    /// A cron expression representing this frequency.
    var cronExpression: String { get }
}

// MARK: - TimeUnits

/// A week of time.
public struct WeekUnit {}

/// A day of time.
public struct DayUnit {}

/// An hour of time.
public struct HourUnit {}

/// A minute of time.
public struct MinuteUnit {}

/// A second of time.
public struct SecondUnit {}

// MARK: - Frequencies

/// A generic frequency for handling amounts of time.
public struct FrequencyTyped<T>: Frequency {
    /// The frequency at which this work should be repeated.
    let value: Int
    
    public var cronExpression: String

    fileprivate init(value: Int, cronExpression: String) {
        self.value = value
        self.cronExpression = cronExpression
    }
}

/// A frequency measured in a number of seconds.
public typealias Seconds = FrequencyTyped<SecondUnit>

/// A frequency measured in a number of minutes.
public typealias Minutes = FrequencyTyped<MinuteUnit>
extension Minutes {
    /// When this frequency should first take place.
    ///
    /// - Parameter sec: A second of a minute (0-59).
    /// - Returns: A minutely frequency that first takes place at the
    ///   given component.
    public func at(sec: Int = 0) -> Minutes {
        Minutes(value: self.value, cronExpression: "\(sec) */\(self.value) * * * *")
    }
}

/// A frequency measured in a number of hours.
public typealias Hours = FrequencyTyped<HourUnit>
extension Hours {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - min: A minute of an hour (0-59).
    ///   - sec: A second of a minute (0-59).
    /// - Returns: An hourly frequency that first takes place at the
    ///   given components.
    public func at(min: Int = 0, sec: Int = 0) -> Hours {
        Hours(value: self.value, cronExpression: "\(sec) \(min) */\(self.value) * * * *")
    }
}

/// A frequency measured in a number of days.
public typealias Days = FrequencyTyped<DayUnit>
extension Days {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - hr: An hour of the day (0-23).
    ///   - min: A minute of an hour (0-59).
    ///   - sec: A second of a minute (0-59).
    /// - Returns: A daily frequency that first takes place at the
    ///   given components.
    public func at(hr: Int = 0, min: Int = 0, sec: Int = 0) -> Days {
        Days(value: self.value, cronExpression: "\(sec) \(min) \(hr) */\(self.value) * * *")
    }
}

/// A frequency measured in a number of weeks.
public typealias Weeks = FrequencyTyped<WeekUnit>
extension Weeks {
    /// When this frequency should first take place.
    ///
    /// - Parameters:
    ///   - hr: An hour of the day (0-23).
    ///   - min: A minute of an hour (0-59).
    ///   - sec: A second of a minute (0-59).
    /// - Returns: A weekly frequency that first takes place at the
    ///   given components.
    public func at(hr: Int = 0, min: Int = 0, sec: Int = 0) -> Weeks {
        Weeks(value: self.value, cronExpression: "\(sec) \(min) \(hr) */\(self.value * 7) * * *")
    }
}

// MARK: - Misc

extension Int {
    /// A frequence of weeks.
    public var weeks: Weeks { Weeks(value: self, cronExpression: "0 0 0 */\(self * 7) * * *") }

    /// A frequence of days.
    public var days: Days { Days(value: self, cronExpression: "0 0 0 */\(self) * * *") }

    /// A frequence of hours.
    public var hours: Hours { Hours(value: self, cronExpression: "0 0 */\(self) * * * *") }

    /// A frequence of minutes.
    public var minutes: Minutes { Minutes(value: self, cronExpression: "0 */\(self) * * * * *") }

    /// A frequence of seconds.
    public var seconds: Seconds { Seconds(value: self, cronExpression: "*/\(self) * * * * * *") }
}
