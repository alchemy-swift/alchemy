import Cron

/// Used to help build schedule frequencies for scheduled tasks.
public struct ScheduleBuilder {
    private let buildingFinished: (Schedule) -> Void
    
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
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfMonth: "\(day)", month: "\(month.rawValue)")
        self.buildingFinished(schedule)
    }
    
    /// Run this task monthly.
    ///
    /// - Parameters:
    ///   - day: The day of the month to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func monthly(day: Int = 1, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfMonth: "\(day)")
        self.buildingFinished(schedule)
    }
    
    /// Run this task weekly.
    ///
    /// - Parameters:
    ///   - day: The day of the week to run.
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func weekly(day: DayOfWeek = .sun, hr: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hr)", dayOfWeek: "\(day.rawValue)")
        self.buildingFinished(schedule)
    }
    
    /// Run this task daily.
    ///
    /// - Parameters:
    ///   - hr: The hour to run.
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func daily(hr: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hr)")
        self.buildingFinished(schedule)
    }
    
    /// Run this task every hour.
    ///
    /// - Parameters:
    ///   - min: The minute to run.
    ///   - sec: The second to run.
    public func hourly(min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "*/1")
        self.buildingFinished(schedule)
    }
    
    /// Run this task every minute.
    ///
    /// - Parameters:
    ///   - sec: The second to run.
    public func minutely(sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)")
        self.buildingFinished(schedule)
    }
    
    /// Run this task every second.
    public func secondly() {
        let schedule = Schedule()
        self.buildingFinished(schedule)
    }
    
    
    /// Run this task according to the given cron expression. Second
    /// and year fields are acceptable.
    ///
    /// - Parameter expression: A cron expression.
    public func cron(_ expression: String) {
        let schedule = Schedule(validate: expression)
        self.buildingFinished(schedule)
    }
}

typealias Schedule = DatePattern

extension Schedule {
    /// Initialize with a cron expression. This will crash if the
    /// expression is invalid.
    init(validate cronExpression: String) {
        do {
            self = try DatePattern(cronExpression)
        } catch {
            fatalError("failed to parse cron expression from \(cronExpression). Error was: \(error).")
        }
    }
    
    /// Initialize with pieces of a cron expression. Each piece
    /// defaults to `*`. This will fatal if a piece of the
    /// expression is invalid.
    init(
        second: String = "*",
        minute: String = "*",
        hour: String = "*",
        dayOfMonth: String = "*",
        month: String = "*",
        dayOfWeek: String = "*",
        year: String = "*"
    ) {
        let string = [second, minute, hour, dayOfWeek, month, dayOfWeek, year].joined(separator: " ")
        do {
            self = try DatePattern(string)
        } catch {
            fatalError("failed to parse cron expression from \(string). Error was: \(error).")
        }
    }
}

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
        switch value {
        case 0: self = .sun
        case 1: self = .mon
        case 2: self = .tue
        case 3: self = .wed
        case 4: self = .thu
        case 5: self = .fri
        case 6: self = .sat
        default: fatalError("\(value) isn't a valid day of the week.")
        }
    }
}

/// A month of the year.
public enum Month: Int, ExpressibleByIntegerLiteral {
    /// January
    case jan = 0
    /// February
    case feb = 1
    /// March
    case mar = 2
    /// April
    case apr = 3
    /// May
    case may = 4
    /// June
    case jun = 5
    /// July
    case jul = 6
    /// August
    case aug = 7
    /// September
    case sep = 8
    /// October
    case oct = 9
    /// November
    case nov = 10
    /// December
    case dec = 11
    
    public init(integerLiteral value: Int) {
        switch value {
        case 0: self = .jan
        case 1: self = .feb
        case 2: self = .mar
        case 3: self = .apr
        case 4: self = .may
        case 5: self = .jun
        case 6: self = .jul
        case 7: self = .aug
        case 8: self = .sep
        case 9: self = .oct
        case 10: self = .nov
        case 11: self = .dec
        default: fatalError("\(value) isn't a valid month.")
        }
    }
}
