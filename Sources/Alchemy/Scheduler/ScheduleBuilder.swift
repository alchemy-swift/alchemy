import Cron

public struct ScheduleBuilder {
    let buildingFinished: (Schedule) -> Void
    
    init(_ buildingFinished: @escaping (Schedule) -> Void) {
        self.buildingFinished = buildingFinished
    }
    
    public func yearly(month: Month = .jan, day: Int = 1, hour: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hour)", dayOfMonth: "\(day)", month: "\(month.rawValue)")
        self.buildingFinished(schedule)
    }
    
    public func monthly(day: Int = 1, hour: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hour)", dayOfMonth: "\(day)")
        self.buildingFinished(schedule)
    }
    
    public func weekly(day: DayOfWeek = .sun, hour: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hour)", dayOfWeek: "\(day.rawValue)")
        self.buildingFinished(schedule)
    }
    
    public func daily(hour: Int = 0, min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "\(hour)")
        self.buildingFinished(schedule)
    }
    
    public func hourly(min: Int = 0, sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)", minute: "\(min)", hour: "*/1")
        self.buildingFinished(schedule)
    }
    
    public func minutely(sec: Int = 0) {
        let schedule = Schedule(second: "\(sec)")
        self.buildingFinished(schedule)
    }
    
    public func secondly() {
        let schedule = Schedule()
        self.buildingFinished(schedule)
    }
    
    public func cron(_ expression: String) {
        let schedule = Schedule(validate: expression)
        self.buildingFinished(schedule)
    }
    
    /// Schedules a task at a recurring interval.
    ///
    /// - Parameters:
    ///   - frequency: The frequency at which this `Job` should be
    ///     run. See `Frequency`.
    func every(_ frequency: Frequency) {
        let schedule = Schedule(validate: frequency.cronExpression)
        self.buildingFinished(schedule)
    }
}

typealias Schedule = DatePattern

extension Schedule {
    init(validate cronExpression: String) {
        do {
            self = try DatePattern(cronExpression)
        } catch {
            fatalError("failed to parse cron expression from \(cronExpression). Error was: \(error).")
        }
    }
    
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

public enum DayOfWeek: Int, ExpressibleByIntegerLiteral {
    case sun = 0
    case mon = 1
    case tue = 2
    case wed = 3
    case thu = 4
    case fri = 5
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

public enum Month: Int, ExpressibleByIntegerLiteral {
    case jan = 0
    case feb = 1
    case mar = 2
    case apr = 3
    case may = 4
    case jun = 5
    case jul = 6
    case aug = 7
    case sep = 8
    case oct = 9
    case nov = 10
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
