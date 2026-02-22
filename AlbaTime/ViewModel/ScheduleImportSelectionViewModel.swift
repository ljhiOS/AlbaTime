import Foundation
import SwiftUI

@MainActor
final class ScheduleImportSelectionViewModel: ObservableObject {
    @Published var selectedMonthDate: Date = Date()
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedWeekStart: Date?

    var yearCandidates: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 6)...(currentYear + 6))
    }

    var monthCandidates: [Int] {
        Array(1...12)
    }

    var monthWeeks: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonthDate) else { return [] }

        var starts: [Date] = []
        var cursor = startOfWeekMonday(for: monthInterval.start)
        while cursor < monthInterval.end {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: cursor) ?? cursor
            if weekEnd >= monthInterval.start {
                starts.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 7, to: cursor) ?? cursor
        }
        return starts
    }

    func ensureInitialSelection() {
        syncYearMonthFromDate()
        if selectedWeekStart == nil {
            selectedMonthDate = Date()
            syncYearMonthFromDate()
            selectedWeekStart = monthWeeks.first ?? startOfWeekMonday(for: Date())
        }
    }

    func applySelectedYearMonth() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        let nextDate = Calendar.current.date(from: components) ?? Date()
        selectedMonthDate = nextDate
        selectedWeekStart = monthWeeks.first
    }

    func weekLabel(_ weekStart: Date) -> String {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let weekNo = weekNumberInSelectedMonth(for: weekStart)
        return "\(weekNo)주차 \(weekStart.monthDayText) ~ \(end.monthDayText)"
    }

    private func syncYearMonthFromDate() {
        let calendar = Calendar.current
        selectedYear = calendar.component(.year, from: selectedMonthDate)
        selectedMonth = calendar.component(.month, from: selectedMonthDate)
    }

    private func weekNumberInSelectedMonth(for weekStart: Date) -> Int {
        guard let index = monthWeeks.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: weekStart) }) else {
            return 1
        }
        return index + 1
    }

    private func startOfWeekMonday(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }
}
