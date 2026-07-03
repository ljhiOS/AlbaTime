import SwiftUI

struct ScheduleImportIdleSection: View {
    
    @Binding var name: String
    let onTapManualInput: () -> Void
    let presetDrafts: [TimePresetDraft]
    let shouldShowSchedulePanel: Bool
    let schedulePanelDraft: ScheduleEditDraft
    let defaultBreakTime: Int
    let onSaveSchedulePanelDraft: (ScheduleEditDraft) throws -> Void
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
                    preset: presetDrafts
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
        .overlay(alignment: .top) {
            if ssvm.showManualHint {
                Text("선택한 날짜를 수정한 뒤 저장하세요")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.theme.primary)
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
        if shouldShowSchedulePanel {
            AISavedSchedulesInlinePanel(
                draft: schedulePanelDraft,
                defaultBreakTime: defaultBreakTime,
                requestedWeekStart: ssvm.manualWeekFocus,
                requestToken: ssvm.manualFocusToken,
                requestMonth: ssvm.manualMonthFocus,
                onSaveDraft: onSaveSchedulePanelDraft
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
