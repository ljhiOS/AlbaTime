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
    
    func testHolidayAllowanceIsZeroUnderFifteenWeeklyHours() {
        var bucket = WeeklyHolidayAllowanceCalculator.makeBucket()
        WeeklyHolidayAllowanceCalculator.addHours(
            14,
            on: makeDate(2026, 7, 6),
            calendar: Calendar(identifier: .gregorian),
            to: &bucket
        )
        
        let result = WeeklyHolidayAllowanceCalculator.holidayPay(from: bucket, hourlyWage: 10_000)
        
        XCTAssertEqual(result, 0)
    }
    
    func testHolidayAllowanceUsesProportionalHoursUnderFortyWeeklyHours() {
        var bucket = WeeklyHolidayAllowanceCalculator.makeBucket()
        WeeklyHolidayAllowanceCalculator.addHours(
            20,
            on: makeDate(2026, 7, 6),
            calendar: Calendar(identifier: .gregorian),
            to: &bucket
        )
        
        let result = WeeklyHolidayAllowanceCalculator.holidayPay(from: bucket, hourlyWage: 10_000)
        
        XCTAssertEqual(result, 40_000)
    }
    
    func testHolidayAllowanceUsesEightHoursAtFortyWeeklyHours() {
        var bucket = WeeklyHolidayAllowanceCalculator.makeBucket()
        WeeklyHolidayAllowanceCalculator.addHours(
            40,
            on: makeDate(2026, 7, 6),
            calendar: Calendar(identifier: .gregorian),
            to: &bucket
        )
        
        let result = WeeklyHolidayAllowanceCalculator.holidayPay(from: bucket, hourlyWage: 10_000)
        
        XCTAssertEqual(result, 80_000)
    }
    
    func testHolidayAllowanceCapsAtEightHoursOverFortyWeeklyHours() {
        var bucket = WeeklyHolidayAllowanceCalculator.makeBucket()
        WeeklyHolidayAllowanceCalculator.addHours(
            50,
            on: makeDate(2026, 7, 6),
            calendar: Calendar(identifier: .gregorian),
            to: &bucket
        )
        
        let result = WeeklyHolidayAllowanceCalculator.holidayPay(from: bucket, hourlyWage: 10_000)
        
        XCTAssertEqual(result, 80_000)
    }
    
    func testTotalMonthlyPayUsesRegularScheduleBreakTimeForFixedPrediction() {
        let workPlace = WorkPlace(
            name: "Fixed",
            hourlyWage: 10_000,
            defaultDays: "",
            defaultStartTime: makeDate(2026, 7, 6, 9, 0),
            defaultEndTime: makeDate(2026, 7, 6, 18, 0),
            defaultRestTime: 60,
            taxType: .none,
            allowanceType: .none,
            workType: .fixed
        )
        workPlace.regularSchedules = [
            RegularSchedule(
                dayOfWeek: "월",
                startTime: makeDate(2026, 7, 6, 9, 0),
                endTime: makeDate(2026, 7, 6, 18, 0),
                breakTime: 30
            )
        ]
        
        let result = SalaryCalculator.calculateTotalMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1)
        )
        
        XCTAssertEqual(result.basicPay, 340_000)
        XCTAssertEqual(result.monthlyWorkHours, 34)
        XCTAssertEqual(result.workingDays, 4)
    }

    func testTotalMonthlyPayUsesWorkRecordInsteadOfPlannedFlexibleSchedule() {
        let workPlace = makeWorkPlace(hourlyWage: 10_000)
        workPlace.targetWeeklyCount = 1
        workPlace.expectedDailyHours = 0
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 6),
                startTime: makeDate(2026, 7, 6, 9, 0),
                endTime: makeDate(2026, 7, 6, 18, 0),
                breakTime: 60
            )
        ]
        workPlace.workRecords = [
            WorkRecord(
                date: makeDate(2026, 7, 6),
                startTime: makeDate(2026, 7, 6, 10, 0),
                endTime: makeDate(2026, 7, 6, 15, 0),
                breakTime: 0
            )
        ]

        let result = SalaryCalculator.calculateTotalMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1)
        )

        XCTAssertEqual(result.basicPay, 50_000)
        XCTAssertEqual(result.totalPay, 50_000)
        XCTAssertEqual(result.monthlyWorkHours, 5)
        XCTAssertEqual(result.workingDays, 5)
    }

    func testAccruedMonthlyPayUsesWorkRecordBreakTime() {
        let workPlace = makeWorkPlace(hourlyWage: 10_000)
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 4),
                startTime: makeDate(2026, 7, 4, 9, 0),
                endTime: makeDate(2026, 7, 4, 18, 0),
                breakTime: 60
            )
        ]
        workPlace.workRecords = [
            WorkRecord(
                date: makeDate(2026, 7, 4),
                startTime: makeDate(2026, 7, 4, 10, 0),
                endTime: makeDate(2026, 7, 4, 18, 0),
                breakTime: 120
            )
        ]

        let result = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: makeDate(2026, 7, 1),
            asOf: makeDate(2026, 7, 4, 19, 0)
        )

        XCTAssertEqual(result.basicPay, 60_000)
        XCTAssertEqual(result.accruedWorkHours, 6)
        XCTAssertEqual(result.workingDays, 1)
    }

    func testScheduleResolverUsesDatedScheduleForBothWorkTypes() throws {
        let date = makeDate(2026, 7, 6)
        let fixed = WorkPlace(
            name: "Fixed",
            hourlyWage: 10_000,
            defaultDays: "월",
            defaultStartTime: makeDate(2026, 7, 6, 9, 0),
            defaultEndTime: makeDate(2026, 7, 6, 18, 0),
            workType: .fixed
        )
        let flexible = makeWorkPlace(hourlyWage: 10_000)

        fixed.workSchedules = [
            WorkSchedule(
                date: date,
                startTime: makeDate(2026, 7, 6, 10, 0),
                endTime: makeDate(2026, 7, 6, 14, 0)
            )
        ]
        flexible.workSchedules = [
            WorkSchedule(
                date: date,
                startTime: makeDate(2026, 7, 6, 10, 0),
                endTime: makeDate(2026, 7, 6, 14, 0)
            )
        ]

        let fixedShift = try XCTUnwrap(ScheduleResolver.resolve(workPlace: fixed, for: date))
        let flexibleShift = try XCTUnwrap(ScheduleResolver.resolve(workPlace: flexible, for: date))

        XCTAssertEqual(fixedShift.startTime, flexibleShift.startTime)
        XCTAssertEqual(fixedShift.endTime, flexibleShift.endTime)
        XCTAssertEqual(fixedShift.startTime, makeDate(2026, 7, 6, 10, 0))
    }

    func testMonthlyPayAppliesHolidayAllowanceOnlyWhenSelected() {
        let withoutHoliday = makeAllowanceWorkPlace(allowanceType: .none)
        let withHoliday = makeAllowanceWorkPlace(allowanceType: .holiday)

        let withoutResult = SalaryCalculator.calculateTotalMonthlyPay(
            workPlaces: [withoutHoliday],
            targetMonth: makeDate(2026, 7, 1)
        )
        let withResult = SalaryCalculator.calculateTotalMonthlyPay(
            workPlaces: [withHoliday],
            targetMonth: makeDate(2026, 7, 1)
        )

        XCTAssertEqual(withoutResult.holidayPay, 0)
        XCTAssertEqual(withoutResult.totalPay, 200_000)
        XCTAssertEqual(withResult.holidayPay, 40_000)
        XCTAssertEqual(withResult.totalPay, 240_000)
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

    private func makeAllowanceWorkPlace(allowanceType: AllowanceType) -> WorkPlace {
        let workPlace = WorkPlace(
            name: "Allowance",
            hourlyWage: 10_000,
            defaultDays: "",
            defaultStartTime: makeDate(2026, 7, 6, 9, 0),
            defaultEndTime: makeDate(2026, 7, 6, 19, 0),
            allowanceType: allowanceType,
            workType: .flexible,
            targetWeeklyCount: 0,
            expectedDailyHours: 0
        )
        workPlace.workSchedules = [
            WorkSchedule(
                date: makeDate(2026, 7, 6),
                startTime: makeDate(2026, 7, 6, 9, 0),
                endTime: makeDate(2026, 7, 6, 19, 0)
            ),
            WorkSchedule(
                date: makeDate(2026, 7, 7),
                startTime: makeDate(2026, 7, 7, 9, 0),
                endTime: makeDate(2026, 7, 7, 19, 0)
            )
        ]
        return workPlace
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
