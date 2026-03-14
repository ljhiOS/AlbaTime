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
        VStack(alignment: .leading, spacing: 10) {
            Text("요일 선택")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let hasSchedule = aspvm.schedulesForSelectedWeek
                        .contains(where: { Calendar.current.isDate($0.date, inSameDayAs: day) })
                    let isSelected = selectedDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false

                    Text(shortWeekdayText(day))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : (hasSchedule ? Color.theme.primary : .primary))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.theme.primary : (hasSchedule ? Color.theme.primary.opacity(0.15) : Color.theme.surface))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            if suppressNextTap {
                                suppressNextTap = false
                                return
                            }
                            selectedDay = day
                        }
                        .onLongPressGesture(minimumDuration: 0.25) {
                            handleDayLongPress(day)
                        }
                }
            }

            if let current = selectedSchedule {
                HStack {
                    DatePicker("", selection: startBinding(for: current), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, twentyFourHourLocale)

                    Text("~")
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: endBinding(for: current), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, twentyFourHourLocale)

                    Spacer()
                }

                Text("삭제를 원하면 요일 버튼을 길게 눌러주세요.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("선택한 요일에 저장된 스케줄이 없어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        if let selectedDay {
                            aspvm.addSchedule(on: selectedDay, context: modelContext)
                        }
                    } label: {
                        Text("이 요일에 스케줄 추가")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.theme.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(selectedDay == nil)
                }
            }
        }
        .padding(10)
        .background(Color.theme.field)
        .cornerRadius(8)
        .onAppear {
            if selectedDay == nil {
                selectedDay = aspvm.schedulesForSelectedWeek.first?.date ?? aspvm.selectedWeekStart ?? Date()
            }
        }
        .onChange(of: aspvm.selectedWeekStart) { _, _ in
            selectedDay = aspvm.schedulesForSelectedWeek
                .first?.date ?? aspvm.selectedWeekStart ?? Date()
        }
    }

    private func shortWeekdayText(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let mondayBasedIndex = (weekday + 5) % 7
        return weekdaySymbols[mondayBasedIndex]
    }

    // 시간 변경 시 AI 편집 플래그를 함께 세팅한다.
    // 이후 저장 시 "AI 데이터가 사용자 수정됨" 상태를 구분할 수 있다.
    private func startBinding(for schedule: WorkSchedule) -> Binding<Date> {
        Binding(
            get: { schedule.startTime },
            set: {
                schedule.startTime = $0
                schedule.isEditedAfterAIImport = true
            }
        )
    }

    // 시간 변경 시 AI 편집 플래그를 함께 세팅한다.
    // 종료 시간 수정도 시작 시간과 동일한 규칙으로 처리한다.
    private func endBinding(for schedule: WorkSchedule) -> Binding<Date> {
        Binding(
            get: { schedule.endTime },
            set: {
                schedule.endTime = $0
                schedule.isEditedAfterAIImport = true
            }
        )
    }

    // 길게 누른 요일의 스케줄을 삭제하고 햅틱 피드백을 제공한다.
    // 롱프레스 직후 탭 오동작을 막기 위해 suppressNextTap 플래그를 함께 제어한다.
    private func handleDayLongPress(_ day: Date) {
        guard aspvm.schedulesForSelectedWeek.contains(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
        }) else {
            return
        }

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
    }
}

#Preview {
    struct PreviewWrapper: View {
        let container: ModelContainer
        let aspvm: AISavedSchedulesPanelViewModel

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

            let s1 = WorkSchedule(
                date: tuesday,
                startTime: tueStart,
                endTime: tueEnd,
                memo: "미들",
                isFromAIImport: true
            )
            let s2 = WorkSchedule(
                date: thursday,
                startTime: thuStart,
                endTime: thuEnd,
                memo: "오픈",
                isFromAIImport: true
            )

            let job = Workplace(
                name: "테스트 매장",
                hourlyWage: 11000,
                defaultDays: "월,화,수,목,금",
                defaultStartTime: weekStart,
                defaultEndTime: weekStart,
                workType: .fixed
            )

            s1.workplace = job
            s2.workplace = job
            job.workSchedules.append(contentsOf: [s1, s2])

            container.mainContext.insert(job)
            container.mainContext.insert(s1)
            container.mainContext.insert(s2)

            let viewModel = AISavedSchedulesPanelViewModel(job: job)
            viewModel.selectedWeekStart = weekStart
            self.aspvm = viewModel
        }

        var body: some View {
            AISavedWeekSingleCard(aspvm: aspvm)
                .padding()
                .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

