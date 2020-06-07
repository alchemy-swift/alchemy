//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation

public enum PeriodicTime {

    case every(minutes: Int)
    case hourly(minute: Int)
    case daily(hour: Int, minute: Int)
    case weekly(day: Day, hour: Int, minute: Int)

    private var unixTime: Int {
        switch self {
        case .every(let minutes):
            return (minutes * 60)
        case .hourly(let hour):
            return (hour * 3600)
        case .daily(let minute, let hour):
            return (minute * 60) + (hour * 3600)
        case .weekly(let day, let hour, let minute):
            return (minute * 60) + (hour * 3600) + (day.rawValue * 86_400)
        }
    }

    var nextTime: Int {
        switch self {
        case .minutely:
            return  Date().unixTime + unixTime
        case .daily:
            let isPast = self.isPast(time: startOfDay().unixTime + unixTime)
            let dateToAdd = isPast ? tomorrow() : startOfDay()
            return dateToAdd.unixTime + unixTime
        case .weekly(let minute, let hour, let day):
            if day.rawValue == today() {
                let time = startOfDay().unixTime + (minute * 60) + (hour * 3600)
                let isPast = self.isPast(time: time)
                if !isPast {
                    return time
                }
            }
            let nextDay = next(day).unixTime + (minute * 60) + (hour * 3600)
            return  nextDay
        }
    }

    var nextTime: Date {
        return Date(timeIntervalSince1970: nextTime)
    }

    func startOfDay() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let unitFlags = Set<Calendar.Component>([.year, .month, .day])
        let components = calendar.dateComponents(unitFlags, from: Date())
        return calendar.date(from: components)!
    }

    func isPast(time: Int) -> Bool {
        return Date().unixTime >= time
    }

    func tomorrow() -> Date {
        return startOfDay().addingTimeInterval(TimeInterval(86_400))
    }

    func today() -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.weekday], from: Date())
        return components.weekday!
    }

    func next(_ day: Day) -> Date {
        let components = Calendar(identifier: .gregorian).dateComponents([.weekday], from: Date())
        let currentWeekday = components.weekday!

        let delta = day.rawValue - currentWeekday
        let adjustedDelta = delta <= 0 ? delta + 7 : delta

        return addDays(adjustedDelta)
    }

    func addDays(_ days: Int) -> Date {
        return startOfDay().addingTimeInterval(TimeInterval(days * 86_400))
    }
}

public enum Day: Int {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
