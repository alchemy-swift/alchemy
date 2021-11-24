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
        Schedule("* * * * * * *", test: self).secondly()
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleMinutely() {
        Schedule("0 * * * * * *", test: self).minutely()
        Schedule("1 * * * * * *", test: self).minutely(sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleHourly() {
        Schedule("0 0 * * * * *", test: self).hourly()
        Schedule("1 2 * * * * *", test: self).hourly(min: 2, sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleDaily() {
        Schedule("0 0 0 * * * *", test: self).daily()
        Schedule("1 2 3 * * * *", test: self).daily(hr: 3, min: 2, sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleWeekly() {
        Schedule("0 0 0 * * 0 *", test: self).weekly()
        Schedule("1 2 3 * * 4 *", test: self).weekly(day: .thu, hr: 3, min: 2, sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleMonthly() {
        Schedule("0 0 0 1 * * *", test: self).monthly()
        Schedule("1 2 3 4 * * *", test: self).monthly(day: 4, hr: 3, min: 2, sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testScheduleYearly() {
        Schedule("0 0 0 1 1 * *", test: self).yearly()
        Schedule("1 2 3 4 5 * *", test: self).yearly(month: .may, day: 4, hr: 3, min: 2, sec: 1)
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testCustomSchedule() {
        Schedule("0 0 22 * * 1-5 *", test: self).expression("0 0 22 * * 1-5 *")
        waitForExpectations(timeout: kMinTimeout)
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
    fileprivate convenience init(_ expectedExpression: String, test: XCTestCase) {
        let exp = test.expectation(description: "")
        self.init {
            XCTAssertEqual($0.cronExpression, expectedExpression)
            exp.fulfill()
        }
    }
}
