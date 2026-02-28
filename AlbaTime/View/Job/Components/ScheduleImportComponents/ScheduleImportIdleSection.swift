import SwiftUI

struct ScheduleImportIdleSection: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var selectedWeekStart: Date?
    @Binding var name: String

    let yearCandidates: [Int]
    let monthCandidates: [Int]
    let monthWeeks: [Date]
    let weekLabel: (Date) -> String
    let onSelectYear: (Int) -> Void
    let onSelectMonth: (Int) -> Void
    let onTapManualInput: () -> Void

    let showManualHint: Bool
    let targetJob: Workplace?
    let hasSavedAISchedules: Bool
    let manualFocusToken: Int
    let manualWeekFocus: Date?
    let manualMonthFocus: AIListMonthKey?

    let isNameFieldFocused: FocusState<Bool>.Binding
    let sivm: ScheduleImportViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                weekSelectorCard
                nameInputCard
                ScheduleImportPresetGroup(
                    sivm: sivm,
                    presets: targetJob?.timePresets ?? []
                )
                savedScheduleSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            isNameFieldFocused.wrappedValue = false
        }
        .overlay(alignment: .bottom) {
            if showManualHint {
                Text("선택한 주차를 수정한 뒤 저장하세요")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
        }
    }

    private var weekSelectorCard: some View {
        ScheduleImportWeekSelectorCard(
            selectedYear: $selectedYear,
            selectedMonth: $selectedMonth,
            selectedWeekStart: $selectedWeekStart,
            yearCandidates: yearCandidates,
            monthCandidates: monthCandidates,
            monthWeeks: monthWeeks,
            onSelectYear: onSelectYear,
            onSelectMonth: onSelectMonth,
            weekLabel: weekLabel,
            onTapManualInput: onTapManualInput
        )
    }

    @ViewBuilder
    private var savedScheduleSection: some View {
        if let job = targetJob, hasSavedAISchedules || manualFocusToken > 0 {
            AISavedSchedulesInlinePanel(
                job: job,
                requestedWeekStart: manualWeekFocus,
                requestToken: manualFocusToken,
                requestMonth: manualMonthFocus
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            ScheduleImportEmptyView()
        }
    }

    private var nameInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("표에 적힌 내 이름")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textPrimary)
                .bold()
            TextField("예: 홍길동 (비워두면 전체 인식)", text: $name)
                .padding(10)
                .background(Color.theme.field)
                .cornerRadius(8)
                .focused(isNameFieldFocused)
        }
        .padding(14)
        .background()
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("Idle Section") {
    struct PreviewWrapper: View {
        @State private var selectedYear: Int = 2026
        @State private var selectedMonth: Int = 2
        @State private var selectedWeekStart: Date? = Calendar.current.startOfDay(for: Date())
        @State private var name: String = "홍길동"
        @FocusState private var isNameFocused: Bool
        @StateObject private var sivm = ScheduleImportViewModel()

        var body: some View {
            ScheduleImportIdleSection(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                selectedWeekStart: $selectedWeekStart,
                name: $name,
                yearCandidates: Array(2020...2030),
                monthCandidates: Array(1...12),
                monthWeeks: [Calendar.current.startOfDay(for: Date())],
                weekLabel: { week in
                    let end = Calendar.current.date(byAdding: .day, value: 6, to: week) ?? week
                    return "\(week.monthDayText) ~ \(end.monthDayText)"
                },
                onSelectYear: { selectedYear = $0 },
                onSelectMonth: { selectedMonth = $0 },
                onTapManualInput: {},
                showManualHint: true,
                targetJob: nil,
                hasSavedAISchedules: false,
                manualFocusToken: 0,
                manualWeekFocus: nil,
                manualMonthFocus: nil,
                isNameFieldFocused: $isNameFocused,
                sivm: sivm
            )
        }
    }

    return PreviewWrapper()
}
