import Foundation
import SwiftUI

// 저장된 AI 스케줄 패널의 상태/필터링/주차 라벨 계산을 담당한다.
// 월/주 선택 상태를 관리하고, 선택 결과에 맞는 스케줄 목록과 표시 문자열을 제공한다.
@MainActor
final class AISavedSchedulesPanelViewModel: ObservableObject {
    @Published var selectedMonthID: String = ""
    @Published var selectedWeekStart: Date?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var forcedMonth: AIListMonthKey?
    @Published var editDraft: ScheduleEditDraft

    private let defaultBreakTime: Int

    init(draft: ScheduleEditDraft, defaultBreakTime: Int) {
        self.defaultBreakTime = defaultBreakTime
        self.editDraft = draft
    }

    // 뷰에서 쓰일 데이터, 뷰에서 건수 나타내거나 비어있는지 확인을 함
    var aiSchedules: [ScheduleEditItem] {
        editDraft.items
            .filter(isVisibleSchedule)
            .sorted(by: sortAISchedules)
    }

    // 뷰에서 년도 월 나열시 쓰임
    var months: [AIListMonthKey] {
        makeMonths(from: aiSchedules, forcedMonth: forcedMonth)
    }

    var selectedMonth: AIListMonthKey? {
        months.first { $0.id == selectedMonthID }
    }

    var monthLabelText: String {
        guard let month = selectedMonth else { return "월 선택" }
        return "\(String(format: "%d", month.year))년 \(month.month)월"
    }

    // 뷰에서 주차 나열후시 쓰임
    var weeks: [AIListWeekItem] {
        makeWeeks(
            from: aiSchedules,
            selectedMonth: selectedMonth,
            selectedWeekStart: selectedWeekStart
        )
    }

    // 뷰에서 주차버튼으로 쓰임
    func weekLabelText(_ week: AIListWeekItem) -> String {
        return "\(dateText(week.start)) ~ \(dateText(week.end)) \(week.count)건"
    }

    // 전체 ai스케줄 중에서 현재 선택한 주만 반환하는 메서드
    var schedulesForSelectedWeek: [ScheduleEditItem] {
        makeSchedulesForSelectedWeek(
            from: aiSchedules,
            selectedWeekStart: selectedWeekStart
        )
    }

    // AISavedSchedulesSelectorRow에서 주차 보여줄때 쓰임
    var weekLabelDisplay: String {
        guard
            let weekStart = selectedWeekStart,
            let selected = weeks.first(where: { Calendar.current.isDate($0.start, inSameDayAs: weekStart) })
        else {
            return "날짜 선택"
        }
        return weekLabelText(selected)
    }

    // 수기로 추가 눌러서 panel 뷰에 보여지면 초기화
    func ensureInitialSelection() {
        if selectedMonthID.isEmpty {
            selectedMonthID = months.first?.id ?? ""
            selectedWeekStart = weeks.first?.start
        }
        clearForcedMonthIfBackedByData()
    }

    // 수기로 추가 눌러서 panel 뷰에 보여지면 초기화
    func focusOnWeek(_ weekStart: Date, preferredMonth: AIListMonthKey? = nil) {
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: weekStart)

        if let preferredMonth {
            forcedMonth = preferredMonth
            selectedMonthID = preferredMonth.id
        } else {
            let comps = calendar.dateComponents([.year, .month], from: normalized)
            let month = AIListMonthKey(year: comps.year ?? 0, month: comps.month ?? 0)
            selectedMonthID = month.id
        }

        selectedWeekStart = normalized
        clearForcedMonthIfBackedByData()
    }

    // AiSavedSchedulesSeletorRow에서 onSelectedMonth형태로 넘어가서 쓰임 버튼에서
    func selectMonth(_ monthID: String) {
        selectedMonthID = monthID
        selectedWeekStart = weeks.first?.start
        clearForcedMonthIfBackedByData()
    }

    // 저장 버튼 누를 시에 뷰에서 호출
    func saveChanges(
        onSaveDraft: (ScheduleEditDraft) throws -> Void
    ) {
        guard !schedulesForSelectedWeek.isEmpty || hasPendingChanges else {
            alertMessage = "선택한 기간에 저장된 스케줄이 없어요."
            showAlert = true
            return
        }

        do {
            try onSaveDraft(editDraft)
            alertMessage = "스케줄 수정사항을 저장했어요."
            showAlert = true
        } catch {
            alertMessage = "저장하지 못했어요.\n\(error.localizedDescription)"
            showAlert = true
        }
    }

    // aiSchedules에 쓰이는 메서드 날
    private func sortAISchedules(_ one: ScheduleEditItem, _ two: ScheduleEditItem) -> Bool {
        // 둘이 다르면 날짜순
        if one.date != two.date { return one.date < two.date }
        // 날짜 같으면 시작 시간 순
        return one.startTime < two.startTime
    }

    // month 만들때 필요
    private func makeMonths(from schedules: [ScheduleEditItem], forcedMonth: AIListMonthKey?) -> [AIListMonthKey] {
        let calendar = Calendar.current
        // 각 스케줄에서 년 월만 뽑기
        var keys = schedules.map {
            let comps = calendar.dateComponents([.year, .month], from: $0.date)
            return AIListMonthKey(year: comps.year ?? 0, month: comps.month ?? 0)
        }

        // 기존에 저장되있던 년 월 데이터 말고 사용자가 필요한 데이터를 view에 보여주기 위해서 필요
        if let forcedMonth = forcedMonth {
            keys.append(forcedMonth)
        }

        return Array(Set(keys)).sorted { // 날짜 큰 순으로 정렬
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }
    }

    // weeks에서 주차 만드는 메뉴 만들때 쓰임
    private func makeWeeks(from schedules: [ScheduleEditItem], selectedMonth: AIListMonthKey?, selectedWeekStart: Date?
    ) -> [AIListWeekItem] {
        guard let month = selectedMonth else { return [] }
        let calendar = Calendar.current

        // 현재 월에 해당하는 스케줄만 걸러냄
        let monthSchedules = schedules.filter {
            let comps = calendar.dateComponents([.year, .month], from: $0.date)
            return comps.year == month.year && comps.month == month.month
        }

        // 주차별로 그룹핑
        var grouped: [Date: [ScheduleEditItem]] = [:]
        for schedule in monthSchedules {
            let start = startOfWeekMonday(for: schedule.date)
            grouped[start, default: []].append(schedule)
        }

        var items = grouped.keys.sorted().map { start in
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return AIListWeekItem(start: start, end: end, count: grouped[start]?.count ?? 0)
        }

        // 현재 선택된 주 목록에 없다면 추가
        if let selectedWeekStart,
           !items.contains(where: { calendar.isDate($0.start, inSameDayAs: selectedWeekStart) }),
           let selected = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedWeekStart) {
            let end = calendar.date(byAdding: .day, value: 6, to: selected) ?? selected
            items.append(AIListWeekItem(start: selected, end: end, count: 0))
            items.sort { $0.start < $1.start }
        }

        return items
    }

    // 전체 workSchedule에서 현재 선택한 주차에 속하는 스케줄만 골라서 반환하는 메서드
    private func makeSchedulesForSelectedWeek(from schedules: [ScheduleEditItem], selectedWeekStart: Date?
    ) -> [ScheduleEditItem] {
        guard let weekStart = selectedWeekStart else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStart)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: start) ?? start

        return schedules.filter {
            $0.date >= start && $0.date < endExclusive
        }
    }

    // 선택월 몇개 주로 나눌지 계산하는 메서드
    private var monthWeekStarts: [Date] {
        guard let month = selectedMonth else { return [] }
        let calendar = Calendar.current

        // 선택 월 1일 만들기 예) 3월고름 3월 1일
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.month
        comps.day = 1

        // 전체 구간 계산
        guard let monthStart = calendar.date(from: comps),
              let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
            return []
        }

        // 그 달에 속한 첫주의 월요일로 주차계산 예) 4월 1일인데 수요일이면 그 주 월요일을 기준으로 잡음
        var starts: [Date] = []
        var cursor = startOfWeekMonday(for: monthInterval.start)

        // 한주씩 돌기
        while cursor < monthInterval.end {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: cursor) ?? cursor
            if weekEnd >= monthInterval.start {
                starts.append(cursor)
            }
            cursor = calendar.date(byAdding: .day, value: 7, to: cursor) ?? cursor
        }
        // 모은 월요일 날짜 반환
        return starts
    }

    private func dateText(_ date: Date) -> String {
        date.monthDayText
    }

    // 주의 월요일 찾는 메서드
    private func startOfWeekMonday(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }

    // forcedMonth에 데이터 저장되면 nil만드는 메서드
    private func clearForcedMonthIfBackedByData() {
        guard let forced = forcedMonth else { return }

        let calendar = Calendar.current
        // 강제로 끼워넣은 월에 데이터 있는지 검사
        let hasDataInForcedMonth = aiSchedules.contains {
            let comps = calendar.dateComponents([.year, .month], from: $0.date)
            return comps.year == forced.year && comps.month == forced.month
        }

        if hasDataInForcedMonth {
            forcedMonth = nil
        }
    }

    private func isVisibleSchedule(_ item: ScheduleEditItem) -> Bool {
        guard item.changeState != .deleted else { return false }

        if editDraft.state == .newJobInitialSchedules {
            return true
        }

        return item.source == .aiImport
    }

    // 수기로 추가 및 ai 인식 스케줄 수정 데이터 저장 로직
    func addSchedule(on day: Date) {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: day)
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate) ?? baseDate
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: baseDate) ?? baseDate
        let source: ScheduleEditSource = editDraft.state == .newJobInitialSchedules ? .manual : .aiImport

        let schedule = ScheduleEditItem(
            id: UUID(),
            date: baseDate,
            startTime: start,
            endTime: end,
            breakTime: defaultBreakTime,
            memo: nil,
            source: source,
            changeState: .inserted
        )

        editDraft.items.append(schedule)
    }

    // 수기 및 ai 추가한 데이터 삭제 로직
    func deleteSchedule(on day: Date) {
        guard let index = editDraft.items.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
            && isVisibleSchedule($0)
        }) else {
            return
        }

        if editDraft.items[index].changeState == .inserted {
            editDraft.items.remove(at: index)
        } else {
            editDraft.items[index].changeState = .deleted
        }
    }

    func deleteSelectedSchedule() {
        guard let weekStart = selectedWeekStart else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStart)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: start) ?? start

        for index in editDraft.items.indices {
            guard
                isVisibleSchedule(editDraft.items[index]),
                editDraft.items[index].date >= start,
                editDraft.items[index].date < endExclusive
            else {
                continue
            }

            if editDraft.items[index].changeState == .inserted {
                editDraft.items[index].changeState = .deleted
            } else {
                editDraft.items[index].changeState = .deleted
            }
        }

        editDraft.items.removeAll { $0.changeState == .deleted && $0.originalScheduleID == nil }
        showAlert = true
        alertMessage = "선택한 스케줄을 삭제했어요."
    }

    // 날짜 선택 시작시간 및 끝시간 업데이트

    func updateStartTime(on day: Date, to newValue: Date) {
        guard let index = editDraft.items.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
            && $0.changeState != .deleted
        }) else { return }

        editDraft.items[index].startTime = newValue
        markUpdated(at: index)
    }

    func updateEndTime(on day: Date, to newValue: Date) {
        guard let index = editDraft.items.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
            && $0.changeState != .deleted
        }) else { return }

        editDraft.items[index].endTime = newValue
        markUpdated(at: index)
    }

    private func markUpdated(at index: Int) {
        guard editDraft.items[index].changeState == .clean else { return }
        editDraft.items[index].changeState = .updated
    }

    private var hasPendingChanges: Bool {
        editDraft.items.contains { $0.changeState != .clean }
    }
}
