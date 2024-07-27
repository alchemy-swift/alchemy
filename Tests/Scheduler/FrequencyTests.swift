@testable import Alchemy
import XCTest

final class FrequencyTests: XCTestCase {
    private var frequency = Frequency()

    override func setUp() {
        super.setUp()
        self.frequency = Frequency()
    }

    func testDayOfWeek() {
        XCTAssertEqual([Frequency.DayOfWeek.sun, .mon, .tue, .wed, .thu, .fri, .sat], [0, 1, 2, 3, 4, 5, 6])
    }

    func testMonth() {
        XCTAssertEqual(
            [Frequency.Month.jan, .feb, .mar, .apr, .may, .jun, .jul, .aug, .sep, .oct, .nov, .dec],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        )
    }

    func testScheduleSecondly() {
        assert("* * * * * * *") { $0.everySecond() }
    }
    
    func testScheduleMinutely() {
        assert("0 * * * * * *") { $0.everyMinute() }
        assert("1 * * * * * *") { $0.everyMinute(sec: 1) }
    }
    
    func testScheduleHourly() {
        assert("0 0 * * * * *") { $0.everyHour() }
        assert("1 2 * * * * *") { $0.everyHour(min: 2, sec: 1) }
    }
    
    func testScheduleDaily() {
        assert("0 0 0 * * * *") { $0.everyDay() }
        assert("1 2 3 * * * *") { $0.everyDay(hr: 3, min: 2, sec: 1) }
    }
    
    func testScheduleWeekly() {
        assert("0 0 0 * * 0 *") { $0.everyWeek() }
        assert("1 2 3 * * 4 *") { $0.everyWeek(day: .thu, hr: 3, min: 2, sec: 1) }
    }
    
    func testScheduleMonthly() {
        assert("0 0 0 1 * * *") { $0.everyMonth() }
        assert("1 2 3 4 * * *") { $0.everyMonth(day: 4, hr: 3, min: 2, sec: 1) }
    }
    
    func testScheduleYearly() {
        assert("0 0 0 1 1 * *") { $0.everyYear() }
        assert("1 2 3 4 5 * *") { $0.everyYear(month: .may, day: 4, hr: 3, min: 2, sec: 1) }
    }
    
    func testCustomSchedule() {
        assert("0 0 22 * * 1-5 *") { $0.cron("0 0 22 * * 1-5 *") }
    }

    func testNext() {
        frequency.everySecond()
        guard let next = frequency.timeUntilNext() else {
            XCTFail()
            return
        }

        XCTAssertLessThanOrEqual(next, .seconds(1))

        frequency.cron("0 0 0 1 * * 2060")
        guard let next = frequency.timeUntilNext() else {
            XCTFail()
            return
        }

        XCTAssertGreaterThan(next, .seconds(60 * 60 * 24 * 365 * 10))
    }
    
    func testNoNext() {
        frequency.cron("0 0 0 11 9 * 1993")
        XCTAssertNil(frequency.timeUntilNext())
    }

    private func assert(_ cron: String, _ builder: (Frequency) -> Void, file: StaticString = #filePath, line: UInt = #line) {
        builder(frequency)
        XCTAssertEqual(cron, frequency.cron.string, file: file, line: line)
    }
}
