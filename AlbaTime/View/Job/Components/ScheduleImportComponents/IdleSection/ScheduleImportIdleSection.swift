import SwiftUI

struct ScheduleImportIdleSection: View {
    
    @Binding var name: String
    let onTapManualInput: () -> Void
    let targetJob: Workplace?
    let hasSavedAISchedules: Bool
    let isNameFieldFocused: FocusState<Bool>.Binding
    let sivm: ScheduleImportViewModel
    @ObservedObject var ssvm: ScheduleImportSelectionViewModel

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
            if ssvm.showManualHint {
                Text("선택한 날짜를 수정한 뒤 저장하세요")
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
            ssvm: ssvm,
            onTapManualInput: onTapManualInput
        )
    }

    @ViewBuilder
    private var savedScheduleSection: some View {
        if let job = targetJob, hasSavedAISchedules || ssvm.manualFocusToken > 0 {
            AISavedSchedulesInlinePanel(
                job: job,
                requestedWeekStart: ssvm.manualWeekFocus,
                requestToken: ssvm.manualFocusToken,
                requestMonth: ssvm.manualMonthFocus
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
                .background(Color.theme.surface)
                .cornerRadius(8)
                .focused(isNameFieldFocused)
        }
        .padding(14)
        .background(Color.theme.field)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("Idle Section") {
    struct PreviewWrapper: View {
        @State private var name: String = "홍길동"
        @FocusState private var isNameFocused: Bool
        @StateObject private var sivm = ScheduleImportViewModel()
        @StateObject private var ssvm = ScheduleImportSelectionViewModel()

        var body: some View {
            ScheduleImportIdleSection(
                name: $name,
                onTapManualInput: {},
                targetJob: nil,
                hasSavedAISchedules: false,
                isNameFieldFocused: $isNameFocused,
                sivm: sivm,
                ssvm: ssvm
            )
            .onAppear {
                ssvm.ensureInitialSelection()
            }
        }
    }

    return PreviewWrapper()
}

