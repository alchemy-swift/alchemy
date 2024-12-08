@testable
import Alchemy
import Testing

struct FrequencyTests {
    private let frequency = Frequency()

    @Test func dayOfWeek() {
        #expect([Frequency.DayOfWeek.sun, .mon, .tue, .wed, .thu, .fri, .sat] == [0, 1, 2, 3, 4, 5, 6])
    }

    @Test func month() {
        let months: [Frequency.Month] = [.jan, .feb, .mar, .apr, .may, .jun, .jul, .aug, .sep, .oct, .nov, .dec]
        #expect(months == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    }

    @Test func scheduleSecondly() {
        expect("* * * * * * *") { $0.everySecond() }
    }
    
    @Test func scheduleMinutely() {
        expect("0 * * * * * *") { $0.everyMinute() }
        expect("1 * * * * * *") { $0.everyMinute(sec: 1) }
    }
    
    @Test func scheduleHourly() {
        expect("0 0 * * * * *") { $0.everyHour() }
        expect("1 2 * * * * *") { $0.everyHour(min: 2, sec: 1) }
    }
    
    @Test func scheduleDaily() {
        expect("0 0 0 * * * *") { $0.everyDay() }
        expect("1 2 3 * * * *") { $0.everyDay(hr: 3, min: 2, sec: 1) }
    }
    
    @Test func scheduleWeekly() {
        expect("0 0 0 * * 0 *") { $0.everyWeek() }
        expect("1 2 3 * * 4 *") { $0.everyWeek(day: .thu, hr: 3, min: 2, sec: 1) }
    }
    
    @Test func scheduleMonthly() {
        expect("0 0 0 1 * * *") { $0.everyMonth() }
        expect("1 2 3 4 * * *") { $0.everyMonth(day: 4, hr: 3, min: 2, sec: 1) }
    }
    
    @Test func scheduleYearly() {
        expect("0 0 0 1 1 * *") { $0.everyYear() }
        expect("1 2 3 4 5 * *") { $0.everyYear(month: .may, day: 4, hr: 3, min: 2, sec: 1) }
    }
    
    @Test func customSchedule() {
        expect("0 0 22 * * 1-5 *") { $0.cron("0 0 22 * * 1-5 *") }
    }

    @Test func next() {
        frequency.everySecond()
        guard let next = frequency.timeUntilNext() else {
            Issue.record()
            return
        }

        #expect(next <= .seconds(1))

        frequency.cron("0 0 0 1 * * 2060")
        guard let next = frequency.timeUntilNext() else {
            Issue.record()
            return
        }

        #expect(next > .seconds(60 * 60 * 24 * 365 * 10))
    }
    
    @Test func noNext() {
        frequency.cron("0 0 0 11 9 * 1993")
        #expect(frequency.timeUntilNext() == nil)
    }

    private func expect(_ cron: String, _ builder: (Frequency) -> Void, sourceLocation: Testing.SourceLocation = #_sourceLocation) {
        builder(frequency)
        #expect(cron == frequency.cron.string, sourceLocation: sourceLocation)
    }
}
