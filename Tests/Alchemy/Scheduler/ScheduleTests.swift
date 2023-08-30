@testable import Alchemy
import XCTest

final class ScheduleTests: XCTestCase {
    func testDayOfWeek() {
        XCTAssertEqual([Frequency.DayOfWeek.sun, .mon, .tue, .wed, .thu, .fri, .sat, .sun], [0, 1, 2, 3, 4, 5, 6, 7])
    }
    
    func testMonth() {
        XCTAssertEqual(
            [Frequency.Month.jan, .feb, .mar, .apr, .may, .jun, .jul, .aug, .sep, .oct, .nov, .dec, .jan],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
        )
    }
    
    func testScheduleSecondly() {
        Frequency("* * * * * * *").everySecond()
    }
    
    func testScheduleMinutely() {
        Frequency("0 * * * * * *").everyMinute()
        Frequency("1 * * * * * *").everyMinute(sec: 1)
    }
    
    func testScheduleHourly() {
        Frequency("0 0 * * * * *").everyHour()
        Frequency("1 2 * * * * *").everyHour(min: 2, sec: 1)
    }
    
    func testScheduleDaily() {
        Frequency("0 0 0 * * * *").everyDay()
        Frequency("1 2 3 * * * *").everyDay(hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleWeekly() {
        Frequency("0 0 0 * * 0 *").everyWeek()
        Frequency("1 2 3 * * 4 *").everyWeek(day: .thu, hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleMonthly() {
        Frequency("0 0 0 1 * * *").everyMonth()
        Frequency("1 2 3 4 * * *").everyMonth(day: 4, hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleYearly() {
        Frequency("0 0 0 1 1 * *").everyYear()
        Frequency("1 2 3 4 5 * *").everyYear(month: .may, day: 4, hr: 3, min: 2, sec: 1)
    }
    
    func testCustomSchedule() {
        Frequency("0 0 22 * * 1-5 *").cron("0 0 22 * * 1-5 *")
    }
    
    func testNext() {
        Frequency { schedule in
            let next = schedule.next()
            XCTAssertNotNil(next)
            if let next = next {
                XCTAssertLessThanOrEqual(next, .seconds(1))
            }
        }.everySecond()
        
        Frequency { schedule in
            let next = schedule.next()
            XCTAssertNotNil(next)
            if let next = next {
                XCTAssertGreaterThan(next, .hours(24 * 365 * 10))
            }
        }.cron("0 0 0 1 * * 2060")
    }
    
    func testNoNext() {
        Frequency { XCTAssertNil($0.next()) }.cron("0 0 0 11 9 * 1993")
    }
}

extension Frequency {
    fileprivate convenience init(_ expectedExpression: String) {
        self.init { XCTAssertEqual($0.cronExpression, expectedExpression) }
    }
}
