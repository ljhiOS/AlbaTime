import SwiftUI
import SwiftData

// 저장된 AI 스케줄 패널의 UI 조합만 담당한다.
// 상단 타이틀/월주 선택/주차 카드/저장 버튼을 렌더링하고,
// 상태/계산/저장 로직은 AISavedSchedulesPanelViewModel로 위임한다.
struct AISavedSchedulesInlinePanel: View {
    let job: Workplace

    @Environment(\.modelContext) private var modelContext
    @StateObject private var aspvm: AISavedSchedulesPanelViewModel

    init(job: Workplace) {
        self.job = job
        _aspvm = StateObject(wrappedValue: AISavedSchedulesPanelViewModel(job: job))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("저장된 AI 스케줄", systemImage: "tray.full")
                    .font(.headline)
                Spacer()
                Text("\(aspvm.aiSchedules.count)건")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
            }

            if aspvm.aiSchedules.isEmpty {
                Text("이 근무지에 저장된 AI 스케줄이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                AISavedSchedulesSelectorRow(
                    months: aspvm.months,
                    selectedMonthID: $aspvm.selectedMonthID,
                    weeks: aspvm.weeks,
                    selectedWeekStart: $aspvm.selectedWeekStart,
                    monthLabelText: aspvm.monthLabelText,
                    weekLabelDisplay: aspvm.weekLabelDisplay,
                    weekLabelText: aspvm.weekLabelText
                )

                if aspvm.schedulesForSelectedWeek.isEmpty {
                    Text("선택한 주차에 저장된 스케줄이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    // 주차 내 편집은 단일 카드에서 요일 전환 방식으로 처리한다.
                    // 여러 행 리스트 대신 한 카드에서 월~일을 선택해 시간을 수정한다.
                    AISavedWeekSingleCard(
                        job: job,
                        weekStart: aspvm.selectedWeekStart ?? aspvm.schedulesForSelectedWeek.first?.date ?? Date(),
                        schedules: aspvm.schedulesForSelectedWeek
                    )

                    Button("선택한 주차 수정사항 저장") {
                        // 현재 인라인 편집 상태를 SwiftData에 반영하고 동기화한다.
                        aspvm.saveChanges(context: modelContext)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            aspvm.ensureInitialSelection()
        }
        .alert("알림", isPresented: $aspvm.showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(aspvm.alertMessage)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        WorkSchedule.self,
        WorkTimePreset.self,
        RegularSchedule.self,
        configurations: config
    )

    let calendar = Calendar.current
    let baseDate = calendar.startOfDay(for: Date())
    let job = Workplace(
        name: "GS25 강남점",
        hourlyWage: 10320,
        defaultDays: "월,화,수",
        defaultStartTime: baseDate,
        defaultEndTime: baseDate,
        workType: .flexible
    )

    let start1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate) ?? baseDate
    let end1 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: baseDate) ?? baseDate
    let nextDay = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
    let start2 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: nextDay) ?? nextDay
    let end2 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: nextDay) ?? nextDay

    let s1 = WorkSchedule(date: baseDate, startTime: start1, endTime: end1, memo: "오픈", isFromAIImport: true, workplace: job)
    let s2 = WorkSchedule(date: nextDay, startTime: start2, endTime: end2, memo: "미들", isFromAIImport: true, workplace: job)
    job.workSchedules.append(contentsOf: [s1, s2])

    container.mainContext.insert(job)
    container.mainContext.insert(s1)
    container.mainContext.insert(s2)

    return AISavedSchedulesInlinePanel(job: job)
        .padding()
        .modelContainer(container)
}
