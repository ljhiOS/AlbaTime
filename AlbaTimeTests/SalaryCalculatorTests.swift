import XCTest
@testable import AlbaTime

@MainActor
final class SalaryCalculatorTests: XCTestCase {
    func testAccruedMonthlyPayIncludesOnlyFinishedSchedules() {
        let workPlace = makeWorkPlace(hourlyWage: 10_000)
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 4),
                startTime: makeDate(2026, 7, 4, 9, 0),
                endTime: makeDate(2026, 7, 4, 13, 0),
                breakTime: 0
            )
        ]

        let beforeShiftEnds = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 4, 12, 0)
        )
        let afterShiftEnds = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 4, 14, 0)
        )

        XCTAssertEqual(beforeShiftEnds.totalPay, 0)
        XCTAssertEqual(beforeShiftEnds.workingDays, 0)
        XCTAssertEqual(afterShiftEnds.basicPay, 40_000)
        XCTAssertEqual(afterShiftEnds.totalPay, 40_000)
        XCTAssertEqual(afterShiftEnds.accruedWorkHours, 4)
        XCTAssertEqual(afterShiftEnds.workingDays, 1)
    }

    func testAccruedMonthlyPayAppliesBreakTimeFromActualSchedule() {
        let workPlace = makeWorkPlace(hourlyWage: 10_000)
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 4),
                startTime: makeDate(2026, 7, 4, 9, 0),
                endTime: makeDate(2026, 7, 4, 18, 0),
                breakTime: 60
            )
        ]

        let result = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 4, 19, 0)
        )

        XCTAssertEqual(result.basicPay, 80_000)
        XCTAssertEqual(result.totalPay, 80_000)
        XCTAssertEqual(result.accruedWorkHours, 8)
        XCTAssertEqual(result.workingDays, 1)
    }

    func testAccruedMonthlyPayHandlesOvernightScheduleAfterEndTime() {
        let workPlace = makeWorkPlace(hourlyWage: 10_000)
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 4),
                startTime: makeDate(2026, 7, 4, 22, 0),
                endTime: makeDate(2026, 7, 5, 2, 0),
                breakTime: 0
            )
        ]

        let beforeShiftEnds = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 5, 1, 0)
        )
        let afterShiftEnds = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 5, 3, 0)
        )

        XCTAssertEqual(beforeShiftEnds.totalPay, 0)
        XCTAssertEqual(beforeShiftEnds.workingDays, 0)
        XCTAssertEqual(afterShiftEnds.basicPay, 40_000)
        XCTAssertEqual(afterShiftEnds.totalPay, 40_000)
        XCTAssertEqual(afterShiftEnds.accruedWorkHours, 4)
        XCTAssertEqual(afterShiftEnds.workingDays, 1)
    }

    private func makeWorkPlace(hourlyWage: Int) -> WorkPlace {
        WorkPlace(
            name: "Test",
            hourlyWage: hourlyWage,
            defaultDays: "",
            defaultStartTime: makeDate(2026, 7, 4, 9, 0),
            defaultEndTime: makeDate(2026, 7, 4, 18, 0),
            taxType: .none,
            allowanceType: .none,
            workType: .flexible
        )
    }

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? Date()
    }
}
