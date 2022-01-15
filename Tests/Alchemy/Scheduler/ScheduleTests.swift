@testable import Alchemy
import XCTest

final class ScheduleTests: XCTestCase {
    func testDayOfWeek() {
        XCTAssertEqual([DayOfWeek.sun, .mon, .tue, .wed, .thu, .fri, .sat, .sun], [0, 1, 2, 3, 4, 5, 6, 7])
    }
    
    func testMonth() {
        XCTAssertEqual(
            [Month.jan, .feb, .mar, .apr, .may, .jun, .jul, .aug, .sep, .oct, .nov, .dec, .jan],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
        )
    }
    
    func testScheduleSecondly() {
        Schedule("* * * * * * *").secondly()
    }
    
    func testScheduleMinutely() {
        Schedule("0 * * * * * *").minutely()
        Schedule("1 * * * * * *").minutely(sec: 1)
    }
    
    func testScheduleHourly() {
        Schedule("0 0 * * * * *").hourly()
        Schedule("1 2 * * * * *").hourly(min: 2, sec: 1)
    }
    
    func testScheduleDaily() {
        Schedule("0 0 0 * * * *").daily()
        Schedule("1 2 3 * * * *").daily(hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleWeekly() {
        Schedule("0 0 0 * * 0 *").weekly()
        Schedule("1 2 3 * * 4 *").weekly(day: .thu, hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleMonthly() {
        Schedule("0 0 0 1 * * *").monthly()
        Schedule("1 2 3 4 * * *").monthly(day: 4, hr: 3, min: 2, sec: 1)
    }
    
    func testScheduleYearly() {
        Schedule("0 0 0 1 1 * *").yearly()
        Schedule("1 2 3 4 5 * *").yearly(month: .may, day: 4, hr: 3, min: 2, sec: 1)
    }
    
    func testCustomSchedule() {
        Schedule("0 0 22 * * 1-5 *").expression("0 0 22 * * 1-5 *")
    }
    
    func testNext() {
        Schedule { schedule in
            let next = schedule.next()
            XCTAssertNotNil(next)
            if let next = next {
                XCTAssertLessThanOrEqual(next, .seconds(1))
            }
        }.secondly()
        
        Schedule { schedule in
            let next = schedule.next()
            XCTAssertNotNil(next)
            if let next = next {
                XCTAssertGreaterThan(next, .hours(24 * 365 * 10))
            }
        }.expression("0 0 0 1 * * 2060")
    }
    
    func testNoNext() {
        Schedule { XCTAssertNil($0.next()) }.expression("0 0 0 11 9 * 1993")
    }
}

extension Schedule {
    fileprivate convenience init(_ expectedExpression: String) {
        self.init { XCTAssertEqual($0.cronExpression, expectedExpression) }
    }
}
