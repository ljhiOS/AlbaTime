import SwiftUI
import SwiftData

// 선택된 주차의 스케줄을 "한 장의 카드"에서 요일 전환하며 편집한다.
// 월~일 칩 선택, 시작/종료 시간 수정, 롱프레스 삭제 UX를 담당한다.
struct AISavedWeekSingleCard: View {
    @ObservedObject var aspvm: AISavedSchedulesPanelViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var selectedDay: Date?
    @State private var suppressNextTap: Bool = false
    private let weekdaySymbols = ["월", "화", "수", "목", "금", "토", "일"]
    private let twentyFourHourLocale = Locale(identifier: "ko_KR@hc=h23")

    // 현재 주차의 월~일 날짜 배열.
    // 요일 칩 렌더링 순서를 고정하기 위한 데이터다.
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: aspvm.selectedWeekStart ?? Date())
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: start)
        }
    }

    // 선택된 요일에 매핑되는 스케줄 1건.
    // 카드 하단 시간 편집 영역은 이 스케줄을 기준으로 바인딩된다.
    private var selectedSchedule: WorkSchedule? {
        guard let selectedDay else { return nil }
        return aspvm.schedulesForSelectedWeek
            .first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) })
    }

    var body: some View {
            DaySelectUI(
                state: makeState(),
                send: handle
            )
            .onAppear {
                if selectedDay == nil {
                    selectedDay = aspvm.schedulesForSelectedWeek.first?.date ?? aspvm.selectedWeekStart ?? Date()
                }
            }
            .onChange(of: aspvm.selectedWeekStart) { _, _ in
                selectedDay = aspvm.schedulesForSelectedWeek.first?.date ?? aspvm.selectedWeekStart ?? Date()
            }
        }

        private func makeState() -> DaySelectUIState<Date> {
            let chips = weekDays.map { day in
                DaySelectUIChip(
                    id: day,
                    title: shortWeekdayText(day),
                    hasSchedule: aspvm.schedulesForSelectedWeek.contains {
                        Calendar.current.isDate($0.date, inSameDayAs: day)
                    }
                )
            }

            let schedule = selectedSchedule

            return DaySelectUIState(
                chips: chips,
                selectedID: selectedDay,
                startTime: schedule?.startTime,
                endTime: schedule?.endTime,
                emptyMessage: "선택한 요일에 저장된 스케줄이 없어요.",
                addButtonTitle: "이 요일에 스케줄 추가"
            )
        }

        private func handle(_ action: DaySelectUIAction<Date>) {
            switch action {
            case let .tapDay(day):
                if suppressNextTap {
                    suppressNextTap = false
                    return
                }
                selectedDay = day

            case let .longPressDay(day):
                guard aspvm.schedulesForSelectedWeek.contains(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: day)
                }) else { return }

                Haptics.impact(.medium)
                suppressNextTap = true
                aspvm.deleteSchedule(on: day, context: modelContext)

                if let selectedDay, Calendar.current.isDate(selectedDay, inSameDayAs: day) {
                    self.selectedDay = aspvm.schedulesForSelectedWeek
                        .map(\.date)
                        .first(where: { !Calendar.current.isDate($0, inSameDayAs: day) })
                        ?? aspvm.selectedWeekStart
                        ?? Date()
                }

            case .tapAdd:
                guard let selectedDay else { return }
                aspvm.addSchedule(on: selectedDay, context: modelContext)

                // View
            case let .changeStartTime(newValue):
                guard let selectedDay else { return }
                aspvm.updateStartTime(on: selectedDay, to: newValue)

            case let .changeEndTime(newValue):
                guard let selectedDay else { return }
                aspvm.updateEndTime(on: selectedDay, to: newValue)
            }
        }

        private func shortWeekdayText(_ date: Date) -> String {
            let weekday = Calendar.current.component(.weekday, from: date)
            let mondayBasedIndex = (weekday + 5) % 7
            return weekdaySymbols[mondayBasedIndex]
        }
}

#Preview("AI 저장 스케줄 편집") {
    struct PreviewWrapper: View {
        let container: ModelContainer
        let vm: AISavedSchedulesPanelViewModel

        init() {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: Workplace.self,
                WorkSchedule.self,
                RegularSchedule.self,
                WorkTimePreset.self,
                configurations: config
            )

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekday = calendar.component(.weekday, from: today)
            let offsetToMonday = (weekday + 5) % 7
            let weekStart = calendar.date(byAdding: .day, value: -offsetToMonday, to: today) ?? today

            let tuesday = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
            let thursday = calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart

            let tueStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tuesday) ?? tuesday
            let tueEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: tuesday) ?? tuesday
            let thuStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: thursday) ?? thursday
            let thuEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: thursday) ?? thursday

            let job = Workplace(
                name: "테스트 매장",
                hourlyWage: 11000,
                defaultDays: "월,화,수,목,금",
                defaultStartTime: tueStart,
                defaultEndTime: tueEnd,
                defaultRestTime: 60,
                workType: .fixed
            )

            let s1 = WorkSchedule(
                date: tuesday,
                startTime: tueStart,
                endTime: tueEnd,
                breakTime: 60,
                memo: "미들",
                isFromAIImport: true
            )

            let s2 = WorkSchedule(
                date: thursday,
                startTime: thuStart,
                endTime: thuEnd,
                breakTime: 30,
                memo: "오픈",
                isFromAIImport: true
            )

            s1.workplace = job
            s2.workplace = job
            job.workSchedules.append(contentsOf: [s1, s2])

            container.mainContext.insert(job)
            container.mainContext.insert(s1)
            container.mainContext.insert(s2)

            let viewModel = AISavedSchedulesPanelViewModel(job: job)
            viewModel.selectedWeekStart = weekStart
            vm = viewModel
        }

        var body: some View {
            AISavedWeekSingleCard(aspvm: vm)
                .padding()
                .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

