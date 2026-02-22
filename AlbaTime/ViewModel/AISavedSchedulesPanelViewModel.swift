import Foundation
import SwiftData
import SwiftUI

// 저장된 AI 스케줄 패널의 상태/필터링/주차 라벨 계산을 담당한다.
// 월/주 선택 상태를 관리하고, 선택 결과에 맞는 스케줄 목록과 표시 문자열을 제공한다.
@MainActor
final class AISavedSchedulesPanelViewModel: ObservableObject {
    @Published var selectedMonthID: String = ""
    @Published var selectedWeekStart: Date?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let job: Workplace

    init(job: Workplace) {
        self.job = job
    }

    // 근무지에 저장된 AI 스케줄만 날짜/시간 순으로 정렬한다.
    // 뷰에서 바로 리스트/건수 표시에 사용할 기준 데이터다.
    var aiSchedules: [WorkSchedule] {
        job.workSchedules.filter { $0.isFromAIImport }.sorted {
                if $0.date != $1.date { return $0.date < $1.date }
                return $0.startTime < $1.startTime
            }
    }

    // 저장된 AI 스케줄이 존재하는 년/월 목록을 만든다.
    // 월 선택 메뉴의 데이터 소스로 사용한다.
    var months: [AIListMonthKey] {
        let calendar = Calendar.current
        let keys = aiSchedules.map {
            let comps = calendar.dateComponents([.year, .month], from: $0.date)
            return AIListMonthKey(year: comps.year ?? 0, month: comps.month ?? 0)
        }
        return Array(Set(keys)).sorted {
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }
    }

    // 현재 선택된 월 키를 반환한다.
    // selectedMonthID를 실제 년/월 구조체로 변환한다.
    var selectedMonth: AIListMonthKey? {
        months.first { $0.id == selectedMonthID }
    }

    // 선택 월 내에서 실제로 저장된 주차(월요일 시작) 목록을 만든다.
    // 저장된 데이터가 있는 주차만 보여주기 위해 count를 함께 계산한다.
    var weeks: [AIListWeekItem] {
        guard let month = selectedMonth else { return [] }
        let calendar = Calendar.current

        let monthSchedules = aiSchedules.filter {
            let comps = calendar.dateComponents([.year, .month], from: $0.date)
            return comps.year == month.year && comps.month == month.month
        }

        var grouped: [Date: [WorkSchedule]] = [:]
        for schedule in monthSchedules {
            let start = startOfWeekMonday(for: schedule.date)
            grouped[start, default: []].append(schedule)
        }

        return grouped.keys.sorted().map { start in
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return AIListWeekItem(start: start, end: end, count: grouped[start]?.count ?? 0)
        }
    }

    // 현재 선택 주차에 포함되는 스케줄만 반환한다.
    // 주차 단일 카드(AISavedWeekSingleCard)의 입력 데이터가 된다.
    var schedulesForSelectedWeek: [WorkSchedule] {
        guard let weekStart = selectedWeekStart else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStart)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return aiSchedules.filter { schedule in schedule.date >= start && schedule.date < endExclusive }
    }

    // 월 선택 버튼용 표시 문자열.
    // 예: "2026년 2월"
    var monthLabelText: String {
        guard let month = selectedMonth else { return "월 선택" }
        return "\(String(format: "%d", month.year))년 \(month.month)월"
    }

    // 주 선택 버튼용 표시 문자열.
    // 선택된 주차가 없으면 기본 문구를 반환한다.
    var weekLabelDisplay: String {
        guard let weekStart = selectedWeekStart,
              let selected = weeks.first(where: { Calendar.current.isDate($0.start, inSameDayAs: weekStart) }) else {
            return "주 선택"
        }
        return weekLabelText(selected)
    }

    // 패널 최초 진입 시 기본 선택 월/주를 세팅한다.
    // 최신 데이터가 있는 월과 그 월의 첫 저장 주차를 기본값으로 선택한다.
    func ensureInitialSelection() {
        if selectedMonthID.isEmpty {
            selectedMonthID = months.first?.id ?? ""
            selectedWeekStart = weeks.first?.start
        }
    }

    // 주차 버튼 리스트에서 보여줄 라벨을 만든다.
    // 예: "3주차 (2/17~2/23) 4건"
    func weekLabelText(_ week: AIListWeekItem) -> String {
        let weekNo = weekNumberInSelectedMonth(for: week.start)
        return "\(weekNo)주차 (\(dateText(week.start))~\(dateText(week.end))) \(week.count)건"
    }

    // 인라인 편집 결과를 저장하고 알림/위젯 동기화를 갱신한다.
    // 저장 성공/실패 메시지는 alert 상태로 뷰에 전달한다.
    func saveChanges(context: ModelContext) {
        NotificationManager.shared.refreshNotifications(for: job)
        do {
            try context.save()
            let workplaces = try context.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
            alertMessage = "주차 스케줄 수정사항을 저장했어요."
            showAlert = true
        } catch {
            alertMessage = "저장하지 못했어요.\n\(error.localizedDescription)"
            showAlert = true
        }
    }

    // 선택 월 기준의 전체 주차(월요일 시작) 목록을 만든다.
    // 저장된 주차 순서가 아니라 달력상의 실제 주차 번호 계산에 사용한다.
    private var monthWeekStarts: [Date] {
        guard let month = selectedMonth else { return [] }
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.month
        comps.day = 1
        guard let monthStart = calendar.date(from: comps),
              let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
            return []
        }

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

    // 선택 월 전체 주차 기준으로 "n주차" 번호를 계산한다.
    // 예: 2/16~2/22를 1주차가 아니라 달력상 3주차로 맞춰준다.
    private func weekNumberInSelectedMonth(for weekStart: Date) -> Int {
        guard let index = monthWeekStarts.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: weekStart) }) else {
            return 1
        }
        return index + 1
    }

    private func dateText(_ date: Date) -> String {
        return date.monthDayText
    }

    // 월요일 시작 주차 계산 유틸.
    // 일반적인 사용자는 월부터 주차를 세기에 UX관점에서 월부터 주차 계산을 함.
    // 입력 날짜가 속한 주의 월요일 00:00 시점을 반환한다.
    private func startOfWeekMonday(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }
}
