//
//  ScheduleImportView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import PhotosUI

struct ScheduleImportView: View {
    @Environment(\.dismiss) private var dismiss
    private let scheduleSaving: any ScheduleSaving
    
    @ObservedObject var ajvm: AddJobViewModel
    
    @AppStorage("myScheduleName") private var myName: String = ""
    @StateObject private var sivm: ScheduleImportViewModel
    @StateObject private var ssvm = ScheduleImportSelectionViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @FocusState private var isNameFieldFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(ajvm: AddJobViewModel, scheduleSaving: any ScheduleSaving) {
        self.ajvm = ajvm
        self.scheduleSaving = scheduleSaving
        _sivm = StateObject(wrappedValue: ScheduleImportViewModel(session: ajvm.session))
    }

    var body: some View {
        VStack(spacing: 0) {
            contentView
            bottomButtons
        }
        .navigationTitle("AI 스케줄")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("앨범 선택", systemImage: "photo.badge.plus")
                }
                .tint(colorScheme == .dark ? .white : .black )
            }
        }
        .background(Color.theme.surface)
        .onAppear {
            ssvm.ensureInitialSelection()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await sivm.processSelectedPhoto(item: newItem, targetName: myName)

            }
        }
        // 근무 형태에 따라 에러 처리 버튼 동작을 분기한다.
        .alert("알림", isPresented: Binding(
            get: { sivm.showAlert },
            set: { sivm.showAlert = $0 }
        )) {
            Button("수기로 입력하기", role: .destructive) {
                triggerManualWeekFocus()
            }
            Button("확인", role: .cancel) { }
        } message: {
            Text(sivm.errorMessage + "\n하단의 '수기로 입력하기' 버튼으로 스케줄을 완성할 수 있습니다.")
        }
    }
}

private extension ScheduleImportView {
    @ViewBuilder
    var contentView: some View {
        switch sivm.phase {
        case .idle:
            ScheduleImportIdleSection(
                name: $myName,
                onTapManualInput: {
                    triggerManualWeekFocus()
                },
                presetDrafts: sivm.presetDrafts,
                shouldShowSchedulePanel: sivm.shouldShowSchedulePanel(
                    manualFocusToken: ssvm.manualFocusToken
                ),
                schedulePanelDraft: sivm.makeSchedulePanelDraft(
                    targetWeekStart: ssvm.manualWeekFocus
                ),
                defaultBreakTime: sivm.panelDefaultBreakTime,
                onSaveSchedulePanelDraft: { draft in
                    try sivm.saveSchedulePanelDraft(
                        draft,
                        using: scheduleSaving
                    )
                },
                isNameFieldFocused: $isNameFieldFocused,
                sivm: sivm,
                ssvm: ssvm)
        case .loading:
            ScheduleImportLoadingView(targetName: myName)
        
        case .result:
            ScheduleImportResultList(sivm: sivm)
        }
    }
    
    private func triggerManualWeekFocus() {
        ssvm.requestManualFocus()
        sivm.selectedImage = nil
        sivm.phase = .idle
    }

    @ViewBuilder
    var bottomButtons: some View {
        if sivm.phase == .result {
            ScheduleImportBottomButtons(
                isSaveDisabled: !sivm.hasScheduleDrafts,
                onSave: {
                    if sivm.saveResultSchedules(
                        using: scheduleSaving,
                        targetWeekStart: ssvm.selectedWeekStart
                    ) {
                        dismiss()
                    }
                },
                onManualInput: {
                    triggerManualWeekFocus()
                }
            )
        }
    }

}

#Preview("AI 스케줄 - 빈 상태") {
    let saving = PreviewJobSaving()
    let scheduleSaving = PreviewScheduleSaving()
    let ajvm = AddJobViewModel(type: .fixed, jobSaving: saving)

    NavigationStack {
        ScheduleImportView(ajvm: ajvm, scheduleSaving: scheduleSaving)
    }
}

#Preview("AI 스케줄 - 저장된 데이터 있음") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let d1 = today
    let d2 = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    let openStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: d1) ?? d1
    let openEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: d1) ?? d1
    let middleStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: d2) ?? d2
    let middleEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: d2) ?? d2

    let seed = JobEditingSeed(
        id: UUID(),
        jobDraft: JobDraft(
            name: "GS25 강남점",
            hourlyWage: 11000,
            defaultRestTime: 0,
            defaultMemo: "",
            taxType: .none,
            allowanceType: .none,
            workType: .flexible,
            targetWeeklyCount: 3,
            expectedDailyHours: 5,
            regularSchedules: []
        ),
        scheduleImportDraft: ScheduleImportDraft(
            schedules: [],
            presetDrafts: [
                TimePresetDraft(
                    id: UUID(),
                    label: "오픈",
                    startTime: openStart,
                    endTime: openEnd
                )
            ]
        ),
        savedAIScheduleItems: [
            ScheduleDraftItem(
                id: UUID(),
                originalScheduleID: UUID(),
                date: d1,
                startTime: openStart,
                endTime: openEnd,
                breakTime: 0,
                memo: "오픈",
                source: .aiImport,
                changeState: .clean
            ),
            ScheduleDraftItem(
                id: UUID(),
                originalScheduleID: UUID(),
                date: d2,
                startTime: middleStart,
                endTime: middleEnd,
                breakTime: 0,
                memo: "미들",
                source: .aiImport,
                changeState: .clean
            )
        ],
        initialDefaultRestTime: 0
    )

    let ajvm = AddJobViewModel(
        editingSeed: seed,
        jobSaving: PreviewJobSaving()
    )

    NavigationStack {
        ScheduleImportView(ajvm: ajvm, scheduleSaving: PreviewScheduleSaving())
    }
}

@MainActor
private struct PreviewJobSaving: JobSaving {
    func execute(_ command: JobSaveCommand) throws { }
}

@MainActor
private struct PreviewScheduleSaving: ScheduleSaving {
    func execute(_ command: SaveScheduleCommand) throws { }
}
