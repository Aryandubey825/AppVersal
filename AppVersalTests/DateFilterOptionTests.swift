import XCTest
@testable import AppVersal

final class DateFilterOptionTests: XCTestCase {

    func testAllPresetMatchesEverything() {
        let filter = DateFilterOption.all
        XCTAssertFalse(filter.isFiltered)
        XCTAssertTrue(filter.matches(date: Date()))
        XCTAssertTrue(filter.matches(date: nil))
        XCTAssertTrue(filter.matches(date: Date.distantPast))
    }

    func testTodayMatchesToday() {
        let filter = DateFilterOption.today
        XCTAssertTrue(filter.isFiltered)
        XCTAssertTrue(filter.matches(date: Date()))

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(filter.matches(date: yesterday))
        XCTAssertFalse(filter.matches(date: nil))
    }

    func testPast7DaysMatchesRecent() {
        let filter = DateFilterOption.past7Days
        XCTAssertTrue(filter.isFiltered)
        XCTAssertTrue(filter.matches(date: Date()))

        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        XCTAssertTrue(filter.matches(date: threeDaysAgo))

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        XCTAssertFalse(filter.matches(date: tenDaysAgo))
        XCTAssertFalse(filter.matches(date: nil))
    }

    func testPast30DaysMatchesRecentMonth() {
        let filter = DateFilterOption.past30Days
        XCTAssertTrue(filter.isFiltered)
        XCTAssertTrue(filter.matches(date: Date()))

        let fifteenDaysAgo = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        XCTAssertTrue(filter.matches(date: fifteenDaysAgo))

        let fortyFiveDaysAgo = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        XCTAssertFalse(filter.matches(date: fortyFiveDaysAgo))
    }

    func testThisYearMatchesCurrentYear() {
        let filter = DateFilterOption.thisYear
        XCTAssertTrue(filter.isFiltered)
        XCTAssertTrue(filter.matches(date: Date()))

        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        XCTAssertFalse(filter.matches(date: lastYear))
    }

    func testCustomDateRangeMatching() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let filter = DateFilterOption.custom(start: start, end: end)

        XCTAssertTrue(filter.isFiltered)

        let inside = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5))!
        let before = calendar.date(from: DateComponents(year: 2026, month: 4, day: 30))!
        let after = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15))!

        XCTAssertTrue(filter.matches(date: inside))
        XCTAssertFalse(filter.matches(date: before))
        XCTAssertFalse(filter.matches(date: after))
    }
}
