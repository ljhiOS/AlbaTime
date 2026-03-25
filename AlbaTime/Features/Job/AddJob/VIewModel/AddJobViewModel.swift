//
//  AddJobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData
import SwiftUI

// 역할: 근무지 추가 및 수정 화면의 핵심 상태 및 저장 로직 담당
// 고정/자율 근무 분기, 요일 스케줄 편집, 프리셋관리, 최종 저장 후 알림/위젯 동기화 수행

@MainActor // UI 변경점에 대한 뷰 업데이트 메인스레드에서 할것임을 보장
// 향후 코드 확장시 발생가능한 스레드 안전성 실수 방지 및 뷰와 데이터 바인딩과정에서 발생할수있는 버그 컴파일타임에 차단
class AddJobViewModel: ObservableObject {
    
    var session: JobEditingSession
    
    // UI 상태 // @MainActor 속성 선언 필요
    @Published var isAIImportPresented: Bool = false // 뷰에서 연결된 네비게이션 연결시에 상태 받아서 ScheduleImportView 이동
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    private let initialDefaultRestTime: Int?
    private var hasSavedChanges: Bool = false
    
    // SheduleGroup에서 사용
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    // 케이스 구분 위해서
    
    // 신규 생성 모드
    init(type: WorkType) {
        self.session = JobEditingSession(type: type)
        self.initialDefaultRestTime = nil
    }
    
    // 수정 모드
    init(editingJob: Workplace) {
        self.session = JobEditingSession(editingJob: editingJob)
        self.initialDefaultRestTime = editingJob.defaultRestTime
    }
    
    // MARK: - 유효성 검사 및 AI
    
    // @MainActor 속성선언 필요 메서드
    // AddJobView에서 ai 스케줄 버튼 누를시 호출
    func validateAndOpenAI() {
        if session.jobDraft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        if session.jobDraft.hourlyWage <= 0 {
            errorMessage = "올바른 시급을 입력해주세요."
            showAlert = true
            return
        }
        // 뷰에서 연결된 네비게이션 연결시에 상태 받아서 ScheduleImportView 이동
        isAIImportPresented = true
    }
    
    // MARK: - 요일별 스케줄 로직
    
    // 특정 요일 근무정보 있는지 확인하는 메서드 -> ScheduleGroup에서 사용
    func getSchedule(for day: String) -> RegularScheduleDraft? {
        session.jobDraft.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    // MARK: 스케줄 선택 및 취소
    func updateStartTime(for day: String, to newValue: Date) {
        guard let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.jobDraft.regularSchedules[index].startTime = newValue
    }
    
    func updateEndTime(for day: String, to newValue: Date) {
        guard let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.jobDraft.regularSchedules[index].endTime = newValue
    }

    // 근무 수정 요일 버튼을 위한 메서드 -> SheduleGroup 메서드에서 사용
    func toggleDay(_ day: String) {
        if let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) {
            session.jobDraft.regularSchedules.remove(at: index)
        } else {
            let newSchedule = RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.jobDraft.defaultRestTime
            )
            session.jobDraft.regularSchedules.append(newSchedule)
        }
    }

    // 평일 전체선택 편의기능 제공 -> ScheduleGroup에서 사용
    func resetAllDays() {
        let weekdays = ["월", "화", "수", "목", "금"]
        
        session.jobDraft.regularSchedules = weekdays.map { day in
            RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.jobDraft.defaultRestTime
            )
        }
    }
    
    // MARK: 저장
    func save(context: ModelContext) -> Bool {
        let jobSaveValidator = JobSaveValidator()
        let applyBreakTime = ApplyBreakTime()
        let appWriteCoordinator = AppWriteCoordinator()
        
        let job = applyDraftToJob(context: context)
        
        do {
            switch session.jobDraft.workType {
                    case .fixed:
                        let saveFixedJob = SaveFixedJob(
                            jobSaveValidator: jobSaveValidator,
                            applyBreakTime: applyBreakTime,
                            appWriteCoordinator: appWriteCoordinator
                        )

                        try saveFixedJob.execute(
                            job: job,
                            initialDefaultRestTime: initialDefaultRestTime,
                            context: context
                        )

                    case .flexible:
                        let saveFlexibleJob = SaveFlexibleJob(
                            jobSaveValidator: jobSaveValidator,
                            applyBreakTime: applyBreakTime,
                            appWriteCoordinator: appWriteCoordinator
                        )

                        try saveFlexibleJob.execute(
                            job: job,
                            targetWeeklyCount: session.jobDraft.targetWeeklyCount,
                            expectedDailyHours: session.jobDraft.expectedDailyHours,
                            initialDefaultRestTime: initialDefaultRestTime,
                            context: context
                        )
                    }
            hasSavedChanges = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
            return false
        }
    }
    
    // MARK: 백업
    func restoreEditsIfNeeded(context: ModelContext) {
        guard let editingJob = session.editingJob else { return }
        guard !hasSavedChanges else { return }
        guard !isAIImportPresented else { return }
        
        session.jobDraft = .from(editingJob)
    }
    
    // MARK: 임시 저장소 실제 DB 저장을 위한 변환 함수
    private func applyDraftToJob(context: ModelContext) -> Workplace {
        let job = session.editingJob ?? Workplace(
            name: "",
            hourlyWage: 0,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: session.jobDraft.workType
        )

        job.name = session.jobDraft.name.trimmingCharacters(in: .whitespaces)
        job.hourlyWage = session.jobDraft.hourlyWage
        job.defaultRestTime = session.jobDraft.defaultRestTime
        job.defaultMemo = session.jobDraft.defaultMemo.isEmpty ? nil : session.jobDraft.defaultMemo
        job.taxType = session.jobDraft.taxType
        job.allowanceType = session.jobDraft.allowanceType
        job.workType = session.jobDraft.workType

        if session.jobDraft.workType == .flexible {
            job.targetWeeklyCount = session.jobDraft.targetWeeklyCount
            job.expectedDailyHours = session.jobDraft.expectedDailyHours
            return job
        } else {
            job.targetWeeklyCount = nil
            job.expectedDailyHours = nil
        }

        let existingSchedules = job.regularSchedules
        job.regularSchedules.removeAll()

        for schedule in existingSchedules where schedule.modelContext != nil {
            context.delete(schedule)
        }

        let orderedSchedules = session.jobDraft.regularSchedules.sorted { left, right in
            let leftIndex = days.firstIndex(of: left.dayOfWeek) ?? 0
            let rightIndex = days.firstIndex(of: right.dayOfWeek) ?? 0
            return leftIndex < rightIndex
        }

        for draftSchedule in orderedSchedules {
            let schedule = RegularSchedule(
                dayOfWeek: draftSchedule.dayOfWeek,
                startTime: draftSchedule.startTime,
                endTime: draftSchedule.endTime,
                breakTime: draftSchedule.breakTime
            )
            schedule.workplace = job
            job.regularSchedules.append(schedule)

            if job.modelContext != nil {
                context.insert(schedule)
            }
        }

        job.defaultDays = orderedSchedules.map(\.dayOfWeek).joined(separator: ",")

        if let firstSchedule = orderedSchedules.first {
            job.defaultStartTime = firstSchedule.startTime
            job.defaultEndTime = firstSchedule.endTime
        }

        return job
    }
}
