//
//  ScheduleImportView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import SwiftData
import PhotosUI

// TODO: 너무 뷰 구성이 꼬여있어서 아키텍처 설계 다시 해야할듯 여기는
struct ScheduleImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var ajvm: AddJobViewModel
    
    @AppStorage("myScheduleName") private var myName: String = ""
    @StateObject private var sivm: ScheduleImportViewModel
    @StateObject private var ssvm = ScheduleImportSelectionViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @FocusState private var isNameFieldFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(ajvm: AddJobViewModel) {
        self.ajvm = ajvm
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
                        context: modelContext
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
                        context: modelContext,
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        WorkSchedule.self,
        WorkTimePreset.self,
        RegularSchedule.self,
        configurations: config
    )

    let ajvm = AddJobViewModel(type: .fixed)

    return NavigationStack {
        ScheduleImportView(ajvm: ajvm)
    }
    .modelContainer(container)
}

#Preview("AI 스케줄 - 저장된 데이터 있음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        WorkSchedule.self,
        WorkTimePreset.self,
        RegularSchedule.self,
        configurations: config
    )

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let job = Workplace(
        name: "GS25 강남점",
        hourlyWage: 11000,
        defaultDays: "월,화,수,목,금",
        defaultStartTime: today,
        defaultEndTime: today,
        workType: .flexible
    )

    let d1 = today
    let d2 = calendar.date(byAdding: .day, value: 1, to: today) ?? today

    let s1 = WorkSchedule(
        date: d1,
        startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: d1) ?? d1,
        endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: d1) ?? d1,
        memo: "오픈",
        isFromAIImport: true,
        workplace: job
    )

    let s2 = WorkSchedule(
        date: d2,
        startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: d2) ?? d2,
        endTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: d2) ?? d2,
        memo: "미들",
        isFromAIImport: true,
        workplace: job
    )

    let p1 = WorkTimePreset(
        label: "오픈",
        startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
        endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
    )

    p1.workplace = job
    job.timePresets.append(p1)
    job.workSchedules.append(contentsOf: [s1, s2])

    container.mainContext.insert(job)
    container.mainContext.insert(s1)
    container.mainContext.insert(s2)
    container.mainContext.insert(p1)

    let ajvm = AddJobViewModel(editingJob: job)

    return NavigationStack {
        ScheduleImportView(ajvm: ajvm)
    }
    .modelContainer(container)
}
