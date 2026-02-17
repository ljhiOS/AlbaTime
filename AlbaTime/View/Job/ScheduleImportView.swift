//
//  ScheduleImportView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import SwiftData
import PhotosUI

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
                    // 자율 근무 시 현재 뷰의 로직 실행
                    sivm.isProcessing = false
                    if sivm.parsedSchedules.isEmpty {
                        sivm.addEmptySchedule()
                    }
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
            idleView
        } else if sivm.isProcessing {
            ScheduleImportLoadingView(targetName: myName)
        } else {
            ScheduleImportResultList(sivm: sivm)
        }
    }

    var idleView: some View {
        ScrollView {
            VStack(spacing: 14) {
                weekSelectorCard
                nameInputCard
                savedScheduleSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            isNameFieldFocused = false
        }
    }

    var weekSelectorCard: some View {
        ScheduleImportWeekSelectorCard(
            selectedYear: $ssvm.selectedYear,
            selectedMonth: $ssvm.selectedMonth,
            selectedWeekStart: $ssvm.selectedWeekStart,
            yearCandidates: ssvm.yearCandidates,
            monthCandidates: ssvm.monthCandidates,
            monthWeeks: ssvm.monthWeeks,
            onSelectYear: { year in
                ssvm.selectedYear = year
                ssvm.applySelectedYearMonth()
            },
            onSelectMonth: { month in
                ssvm.selectedMonth = month
                ssvm.applySelectedYearMonth()
            },
            weekLabel: ssvm.weekLabel
        )
    }

    @ViewBuilder
    var savedScheduleSection: some View {
        if let job = targetJob, hasSavedAISchedules {
            AISavedSchedulesInlinePanel(job: job)
        } else {
            ScheduleImportEmptyView()
        }
    }

    @ViewBuilder
    var bottomButtons: some View {
        if sivm.selectedImage != nil {
            ScheduleImportBottomButtons(
                sivm: sivm,
                selectedWeekStart: ssvm.selectedWeekStart,
                onSaved: {
                    // 저장 완료 후 AddJobView로 돌아간다.
                    dismiss()
                },
                onManualInput: {
                    sivm.isProcessing = false
                    if sivm.parsedSchedules.isEmpty {
                        sivm.addEmptySchedule()
                    }
                }
            )
        }
    }

    var nameInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("표에 적힌 내 이름")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("예: 홍길동 (비워두면 전체 인식)", text: $myName)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFieldFocused)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
