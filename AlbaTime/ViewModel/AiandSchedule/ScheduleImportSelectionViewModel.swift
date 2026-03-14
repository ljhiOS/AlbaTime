import Foundation
import SwiftUI

@MainActor
final class ScheduleImportSelectionViewModel: ObservableObject {
    
    @Published var selectedMonthDate: Date = Date()
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedWeekStart: Date?
    
    // 수기 입력 관련, AISavedSchdeulesInlinePanel에서도 쓰임
    @Published var manualWeekFocus: Date?
    @Published var manualMonthFocus: AIListMonthKey?
    @Published var manualFocusToken: Int = 0
    @Published var showManualHint: Bool = false // ScheduleImportIdleSection에서 사용

    // ScheduleImportWeekSelectionCard에서 사용
    var yearCandidates: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 6)...(currentYear + 6))
    }

    // ScheduleImportWeekSelectionCard에서 사용
    var monthCandidates: [Int] {
        Array(1...12)
    }

    // ScheduleImportWeekSelectionCard에서 사용 -> 해당하는 주가 몇주차인지 계산하는 프로퍼티
    var monthWeeks: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonthDate) else { return [] }

        var starts: [Date] = []
        var cursor = startOfWeekMonday(for: monthInterval.start)
        
        // 월요일 기준으로 주차 계산
        while cursor < monthInterval.end {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: cursor) ?? cursor
            if weekEnd >= monthInterval.start {
                starts.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 7, to: cursor) ?? cursor
        }
        return starts
    }
    
    // ScheduleImportView 진입시에 호출 -> 현재 주차에 맞는 주차 보여주기 위해 사용
    func ensureInitialSelection() {
        let now = Date()
        let currentWeekStart = startOfWeekMonday(for: now)
        
        selectedMonthDate = currentWeekStart
        syncYearMonthFromDate()
        selectedWeekStart = currentWeekStart
    }
    // ensureInitialSelection에서 사용 (헬퍼메서드)
    private func syncYearMonthFromDate() {
        let calendar = Calendar.current
        selectedYear = calendar.component(.year, from: selectedMonthDate)
        selectedMonth = calendar.component(.month, from: selectedMonthDate)
    }
    // ensureInitialSelection. monthWeek에서 사용 (헬퍼메서드)
    private func startOfWeekMonday(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }

    // ScheduleImportWeekSelectorCard에서 사용
    func applySelectedYearMonth() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        let nextDate = Calendar.current.date(from: components) ?? Date()
        selectedMonthDate = nextDate
        selectedWeekStart = monthWeeks.first
    }

    // ScheduleImportWeekSelectoeCard에서 사용
    func weekLabel(_ weekStart: Date) -> String {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let weekNo = weekNumberInSelectedMonth(for: weekStart)
        return "\(weekNo)주차 \(weekStart.monthDayText) ~ \(end.monthDayText)"
    }
    
    // weekLabel에서 사용 (헬퍼메서드)
    private func weekNumberInSelectedMonth(for weekStart: Date) -> Int {
        guard let index = monthWeeks.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: weekStart) }) else {
            return 1
        }
        return index + 1
    }

    // ScheduleImportView에서 triggerManualWeekFocus() 구현시 사용 -> 수기입력모드일시 필요한 UI 상태 세팅
    func requestManualFocus() {
        manualWeekFocus = selectedWeekStart
        manualMonthFocus = AIListMonthKey(year: selectedYear, month: selectedMonth)
        // 같은 주차여도 새로운 요청 신호 주기
        manualFocusToken += 1
        
        // UX 힌트 띄우기
        showManualHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showManualHint = false
        }
    }
}
