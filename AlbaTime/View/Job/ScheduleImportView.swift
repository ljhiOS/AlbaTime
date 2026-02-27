//
//  ScheduleImportView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// TODO: ai 스케줄 저장시 주차가 현재 해당하는 주차로 자동적으로 UI에 보이도록 한다.
// TODO: 수기로 입력하기 만들기 주차 선택칸 밑에 수기로 입력하기 버튼 누르고 해당하는 그 주차가 리스트에 추가되어서 수기 저장도 가능하게함
// -> 필요 이유: 현재 자율근무제일 경우 무조건적으로 스케줄표를 ai 스케줄로 입력해야함 따라서 스케줄 표가 없는 자율 근무제 사용자는 그 근무지 설정 자체를 못함

struct ScheduleImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var targetJob: Workplace?
    
    @AppStorage("myScheduleName") private var myName: String = ""
    @StateObject private var sivm = ScheduleImportViewModel()
    @StateObject private var ssvm = ScheduleImportSelectionViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @FocusState private var isNameFieldFocused: Bool
    
    init(targetJob: Workplace? = nil) {
        self.targetJob = targetJob
    }

    var hasSavedAISchedules: Bool {
        guard let job = targetJob else { return false }
        return job.workSchedules.contains(where: { $0.isFromAIImport })
    }

    var body: some View {
        VStack(spacing: 0) {
            contentView
            bottomButtons
        }
        .navigationTitle("AI 스케줄")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("앨범 선택", systemImage: "photo.badge.plus")
                }
                .tint(.black)
            }
        }
        .onAppear {
            if let job = targetJob {
                sivm.setTargetJob(job)
            }
            ssvm.ensureInitialSelection()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await sivm.processSelectedPhoto(item: newItem, targetJob: targetJob, targetName: myName)
            }
        }
        // 근무 형태에 따라 에러 처리 버튼 동작을 분기한다.
        .alert("알림", isPresented: Binding(
            get: { sivm.showAlert },
            set: { sivm.showAlert = $0 }
        )) {
            Button("수기로 입력하기", role: .destructive) {
                let isFixed = targetJob?.workType == .fixed
                if isFixed {
                    dismiss()
                } else {
                    triggerManualWeekFocus()
                }
            }
            Button("확인", role: .cancel) { }
        } message: {
            if let type = targetJob?.workType, type == .flexible {
                Text(sivm.errorMessage + "\n하단의 '수기로 입력하기' 버튼으로 스케줄을 완성할 수 있습니다.")
            } else {
                Text(sivm.errorMessage)
            }
        }
    }
}

private extension ScheduleImportView {
    @ViewBuilder
    var contentView: some View {
        if sivm.selectedImage == nil {
            ScheduleImportIdleSection(
                selectedYear: $ssvm.selectedYear,
                selectedMonth: $ssvm.selectedMonth,
                selectedWeekStart: $ssvm.selectedWeekStart,
                name: $myName,
                yearCandidates: ssvm.yearCandidates,
                monthCandidates: ssvm.monthCandidates,
                monthWeeks: ssvm.monthWeeks,
                weekLabel: ssvm.weekLabel,
                onSelectYear: { year in
                    ssvm.selectedYear = year
                    ssvm.applySelectedYearMonth()
                },
                onSelectMonth: { month in
                    ssvm.selectedMonth = month
                    ssvm.applySelectedYearMonth()
                },
                onTapManualInput: {
                    triggerManualWeekFocus()
                },
                showManualHint: ssvm.showManualHint,
                targetJob: targetJob,
                hasSavedAISchedules: hasSavedAISchedules,
                manualFocusToken: ssvm.manualFocusToken,
                manualWeekFocus: ssvm.manualWeekFocus,
                manualMonthFocus: ssvm.manualMonthFocus,
                isNameFieldFocused: $isNameFieldFocused,
                sivm: sivm
            )
        } else if sivm.isProcessing {
            ScheduleImportLoadingView(targetName: myName)
        } else {
            ScheduleImportResultList(sivm: sivm)
        }
    }
    
    private func triggerManualWeekFocus() {
        ssvm.requestManualFocus()
        sivm.selectedImage = nil
        sivm.isProcessing = false
    }

    @ViewBuilder
    var bottomButtons: some View {
        if sivm.selectedImage != nil {
            ScheduleImportBottomButtons(
                sivm: sivm,
                selectedWeekStart: ssvm.selectedWeekStart,
                onSaved: {
                    dismiss()
                },
                onManualInput: {
                    triggerManualWeekFocus()
                }
            )
        }
    }
}

#Preview("AI 스케줄 - 빈 상태") {
    NavigationStack {
        ScheduleImportView()
    }
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

    job.workSchedules.append(contentsOf: [s1, s2])
    container.mainContext.insert(job)
    container.mainContext.insert(s1)
    container.mainContext.insert(s2)

    return NavigationStack {
        ScheduleImportView(targetJob: job)
    }
    .modelContainer(container)
}
