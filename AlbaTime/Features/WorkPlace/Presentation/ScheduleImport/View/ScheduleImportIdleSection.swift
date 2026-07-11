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
            VStack(spacing: 16) {
                weekSelectorCard
                nameInputCard
                ScheduleImportPresetGroup(
                    sivm: sivm,
                    preset: presetDrafts
                )
                .spotlightTarget(.scheduleImportPresetInput)
                savedScheduleSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            isNameFieldFocused.wrappedValue = false
        }
        .spotlightOnboarding(steps: onboardingSteps)
    }

    private var onboardingSteps: [SpotlightOnboardingStep] {
        [
            SpotlightOnboardingStep(
                key: .scheduleImportDateBase,
                message: "AI가 인식한 스케줄은 선택한 주차 기준으로 저장돼요."
            ),
            SpotlightOnboardingStep(
                key: .scheduleImportNameInput,
                message: "스케줄표에 적힌 이름을 입력하면 내 근무만 더 정확히 찾을 수 있어요."
            ),
            SpotlightOnboardingStep(
                key: .scheduleImportPresetInput,
                message: "오픈, 마감, 미들처럼 시간이 아닌 이름으로 적힌 경우 여기에 등록하면 AI가 인식할 수 있어요."
            )
        ]
    }

    private var weekSelectorCard: some View {
        ScheduleImportWeekSelectorCard(
            ssvm: ssvm,
            onTapManualInput: onTapManualInput
        )
        .spotlightTarget(.scheduleImportDateBase)
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
        .spotlightTarget(.scheduleImportNameInput)
    }
}
