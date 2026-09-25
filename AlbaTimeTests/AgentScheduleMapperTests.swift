import XCTest
@testable import AlbaTime

@MainActor
final class ScheduleImageAnalyzerRoutingTests: XCTestCase {
    func testAnalyzerMatchesOSVersion() {
        let analyzer = WorkPlaceFeatureComposition.makeScheduleImageAnalyzer()

        if #available(iOS 27.0, *) {
            XCTAssertTrue(analyzer is AgentScheduleImageAnalyzer)
        } else {
            XCTAssertTrue(analyzer is AnalyzeScheduleImage)
        }
    }
}

@MainActor
@available(iOS 27.0, *)
final class AgentScheduleMapperTests: XCTestCase {
    func testMapsVisibleTimesOvernightShiftAndPresetToSelectedWeek() throws {
        let weekStart = try XCTUnwrap(Date.parse("2026-09-21", format: "yyyy-MM-dd"))
        let extraction = AIScheduleExtraction(schedules: [
            AISchedule(date: "2026-09-21", startTime: "09:00", endTime: "18:00", workLabel: nil),
            AISchedule(date: "2026-09-22", startTime: "22:00", endTime: "06:00", workLabel: nil),
            AISchedule(date: "2026-09-23", startTime: nil, endTime: nil, workLabel: " 미들 "),
            AISchedule(date: "2026-09-21", startTime: "09:00", endTime: "18:00", workLabel: nil),
            AISchedule(date: "2026-09-24", startTime: "25:00", endTime: "18:00", workLabel: nil),
            AISchedule(date: "2026-09-25", startTime: nil, endTime: nil, workLabel: "미등록"),
            AISchedule(date: "2026-09-28", startTime: "09:00", endTime: "18:00", workLabel: nil)
        ])
        let presets = [AgentSchedulePreset(label: "미들", startTime: "14:00", endTime: "20:00")]

        let schedules = ScheduleMapper().mapping(
            aiSchedules: extraction,
            presets: presets,
            referenceDate: weekStart
        )

        XCTAssertEqual(schedules.count, 3)
        XCTAssertEqual(schedules.map(\.workLabel), [nil, nil, "미들"])
        assertDateTime(schedules[0].date, day: 21, hour: 0, minute: 0)
        assertDateTime(schedules[0].startTime, day: 21, hour: 9, minute: 0)
        assertDateTime(schedules[1].endTime, day: 23, hour: 6, minute: 0)
        assertDateTime(schedules[2].startTime, day: 23, hour: 14, minute: 0)
    }

    func testRejectsIncompleteAndFullDayShiftsButAcceptsMidnightEnd() throws {
        let weekStart = try XCTUnwrap(Date.parse("2026-09-21", format: "yyyy-MM-dd"))
        let extraction = AIScheduleExtraction(schedules: [
            AISchedule(date: "2026-09-21", startTime: "09:00", endTime: nil, workLabel: nil),
            AISchedule(date: "2026-09-22", startTime: "00:00", endTime: "24:00", workLabel: nil),
            AISchedule(date: "2026-09-23", startTime: "17:00", endTime: "24:00", workLabel: nil),
            AISchedule(date: "2026-09-24", startTime: "9:00", endTime: "18:00", workLabel: nil),
            AISchedule(date: "2026-09-25", startTime: nil, endTime: nil, workLabel: nil)
        ])

        let schedules = ScheduleMapper().mapping(
            aiSchedules: extraction,
            presets: [AgentSchedulePreset(label: " ", startTime: "09:00", endTime: "18:00")],
            referenceDate: weekStart
        )

        XCTAssertEqual(schedules.count, 1)
        assertDateTime(schedules[0].endTime, day: 24, hour: 0, minute: 0)
    }

    func testSelectedWeekCanCrossYearBoundary() throws {
        let weekStart = try XCTUnwrap(Date.parse("2026-12-28", format: "yyyy-MM-dd"))
        let extraction = AIScheduleExtraction(schedules: [
            AISchedule(date: "2027-01-01", startTime: "09:00", endTime: "18:00", workLabel: nil),
            AISchedule(date: "2026-12-27", startTime: "09:00", endTime: "18:00", workLabel: nil)
        ])

        let schedules = ScheduleMapper().mapping(
            aiSchedules: extraction,
            presets: [],
            referenceDate: weekStart
        )

        XCTAssertEqual(schedules.count, 1)
        XCTAssertEqual(Calendar.current.component(.year, from: schedules[0].date), 2027)
    }

    private func assertDateTime(
        _ value: Date,
        day: Int,
        hour: Int,
        minute: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: value)
        XCTAssertEqual(components.day, day, file: file, line: line)
        XCTAssertEqual(components.hour, hour, file: file, line: line)
        XCTAssertEqual(components.minute, minute, file: file, line: line)
    }
}
