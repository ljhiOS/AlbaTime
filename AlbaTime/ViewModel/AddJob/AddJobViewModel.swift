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
    
    private struct RegularScheduleBackup {
        let dayOfWeek: String
        let startTime: Date
        let endTime: Date
        let breakTime: Int
    }
    
    private struct JobEditBackup {
        let name: String
        let hourlyWage: Int
        let defaultDays: String
        let defaultStartTime: Date
        let defaultEndTime: Date
        let defaultMemo: String?
        let defaultRestTime: Int?
        let taxTypeRaw: String
        let allowanceTypeRaw: String
        let workTypeRaw: String
        let targetWeeklyCount: Int?
        let expectedDailyHours: Double?
        let regularSchedules: [RegularScheduleBackup]
    }
    
    @Published var job: Workplace
    
    // UI 상태 // @MainActor 속성 선언 필요
    @Published var isAIImportPresented: Bool = false // 뷰에서 연결된 네비게이션 연결시에 상태 받아서 ScheduleImportView 이동
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // FlexibleInfoGroup에서 값 받음
    @Published var targetWeeklyCount: Int = 3
    @Published var expectedDailyHours: Double = 5.0
    
    private let initialDefaultRestTime: Int?
    
    // restoreEditsIfNeeded의 검증 변수 초기화시 값 받음
    private let isEditingExistingJob: Bool
    
    private let originalJobBackup: JobEditBackup?
    private var hasSavedChanges: Bool = false
    
    // SheduleGroup에서 사용
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    // 케이스 구분 위해서
    
    // 신규 생성 모드
    init(type: WorkType) {
        // 객체 생성
        self.job = Workplace(
            name: "",
            hourlyWage: 0,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: type // 선택한 타입으로 생성
        )
        
        // 자율 근무 기본값 세팅
        if type == .flexible {
            self.targetWeeklyCount = 3
            self.expectedDailyHours = 5.0
        }
        //saveJob에서 사용
        self.initialDefaultRestTime = nil
        
        self.isEditingExistingJob = false
        self.originalJobBackup = nil
    }
    
    // 수정 모드
    init(editingJob: Workplace) {
        self.job = editingJob
        //saveJob에서 사용
        self.initialDefaultRestTime = editingJob.defaultRestTime
        
        self.isEditingExistingJob = true
        
        self.originalJobBackup = JobEditBackup(
            name: editingJob.name,
            hourlyWage: editingJob.hourlyWage,
            defaultDays: editingJob.defaultDays,
            defaultStartTime: editingJob.defaultStartTime,
            defaultEndTime: editingJob.defaultEndTime,
            defaultMemo: editingJob.defaultMemo,
            defaultRestTime: editingJob.defaultRestTime,
            taxTypeRaw: editingJob.taxTypeRaw,
            allowanceTypeRaw: editingJob.allowanceTypeRaw,
            workTypeRaw: editingJob.workTypeRaw,
            targetWeeklyCount: editingJob.targetWeeklyCount,
            expectedDailyHours: editingJob.expectedDailyHours,
            regularSchedules: editingJob.regularSchedules.map {
                RegularScheduleBackup(
                    dayOfWeek: $0.dayOfWeek,
                    startTime: $0.startTime,
                    endTime: $0.endTime,
                    breakTime: $0.breakTime
                )
            }
        )
        
        if editingJob.workType == .flexible {
            self.targetWeeklyCount = editingJob.targetWeeklyCount ?? 3
            self.expectedDailyHours = editingJob.expectedDailyHours ?? 5.0
        }
    }
    
    // MARK: - 유효성 검사 및 AI
    
    // @MainActor 속성선언 필요 메서드
    // AddJobView에서 ai 스케줄 버튼 누를시 호출
    func validateAndOpenAI() {
        if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        if job.hourlyWage <= 0 {
            errorMessage = "올바른 시급을 입력해주세요."
            showAlert = true
            return
        }
        // 뷰에서 연결된 네비게이션 연결시에 상태 받아서 ScheduleImportView 이동
        isAIImportPresented = true
    }

    // MARK: - 요일별 스케줄 로직
    
    // 특정 요일 근무정보 있는지 확인하는 메서드 -> ScheduleGroup에서 사용
    func getSchedule(for day: String) -> RegularSchedule? {
        return job.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    // 근무 수정 요일 버튼을 위한 메서드 -> SheduleGroup 메서드에서 사용
    func toggleDay(_ day: String, context: ModelContext) {
        if let schedule = getSchedule(for: day) {
            if let index = job.regularSchedules.firstIndex(of: schedule) {
                job.regularSchedules.remove(at: index)
            }
            
            if job.modelContext != nil {
                context.delete(schedule)
            }
        } else {
            let newSchedule = RegularSchedule(
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: job.defaultRestTime ?? 0
            )
            newSchedule.workplace = job
            job.regularSchedules.append(newSchedule)
            
            if job.modelContext != nil {
                context.insert(newSchedule)
            }
        }
    }
    
    // 평일 전체선택 편의기능 제공 -> ScheduleGroup에서 사용
    func resetAllDays(context: ModelContext) {
        for schedule in job.regularSchedules where schedule.modelContext != nil {
            context.delete(schedule)
        }
        job.regularSchedules.removeAll()
        
        let weekdays = ["월", "화", "수", "목", "금"]
        for day in weekdays {
            let schedule = RegularSchedule(
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: job.defaultRestTime ?? 0
            )
            schedule.workplace = job
            job.regularSchedules.append(schedule)
            
            if job.modelContext != nil {
                context.insert(schedule)
            }
        }
    }

    // MARK: - 저장 로직 (Save)
    
    // 데이터 베이스 저장 -> 뷰에서 저장버튼 누를때 호출
    func saveJob(context: ModelContext) -> Bool {
        // 1. 유효성 검사 (먼저 수행)
        if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return false
        }
        if job.hourlyWage <= 0 {
            errorMessage = "올바른 시급을 입력해주세요."
            showAlert = true
            return false
        }
        
        if job.modelContext == nil {
            context.insert(job)
        }

        let updatedBreakTime = max(0, job.defaultRestTime ?? 0)
        
        // initialDefaultRestTime -> 신규일때 nil, 수정일땐 editingJob.defaultRestTime
        if job.defaultRestTime == nil {
            for schedule in job.regularSchedules { schedule.breakTime = 0 }
            for schedule in job.workSchedules { schedule.breakTime = 0 }
        } else if initialDefaultRestTime != job.defaultRestTime { // 수정일때 필요
            let previousBreakTime = max(0, initialDefaultRestTime ?? 0)
            for schedule in job.regularSchedules where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
            for schedule in job.workSchedules where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
        } else { // 기본 휴게시간 유지
            for schedule in job.regularSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
            for schedule in job.workSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
        }
        
        // 2. UI 상태값을 모델에 반영 및 정리
        if job.workType == .flexible {
            job.targetWeeklyCount = targetWeeklyCount
            job.expectedDailyHours = expectedDailyHours
            
            // 고정근무가 아니기에 DB 삭제
            let schedulesToDelete = job.regularSchedules
            job.regularSchedules.removeAll()
            schedulesToDelete.forEach { context.delete($0) }
            
        } else {
            // 고정 근무: 자율 근무용 변수 초기화
            job.targetWeeklyCount = nil
            job.expectedDailyHours = nil
            
            // 고정 근무인데 요일 설정이 하나도 없으면 경고 (단, AI로 인식한 스케줄이 있으면 통과)
            if job.regularSchedules.isEmpty && job.workSchedules.isEmpty {
                errorMessage = "요일별 근무 시간 입력 또는 AI 스케줄을 인식해주세요."
                showAlert = true
                return false
            }
        }
        
        // 3. 알림 갱신 로직
        NotificationManager.shared.refreshNotifications(for: job)
        
        // 4. 최종 저장
        do {
            try context.save()
            hasSavedChanges = true
            let workplaces = try context.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
            return true
        } catch {
            print("저장 실패: \(error)")
            errorMessage = "저장 중 오류가 발생했어요.\n\(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // 수정 모드에서 저장 없이 화면을 나가면 원본값으로 되돌린다.
    // AI 스케줄 화면으로 push 될 때는 AddJob 화면이 사라져도 복원하지 않는다.
    func restoreEditsIfNeeded(context: ModelContext) {
        guard isEditingExistingJob else { return }
        // onDisappear일시 호출되기에 저장된거 복원되는거 막기
        guard !hasSavedChanges else { return }
        // onDisappear일시 호출되기에 ScheduleImportView 넘어갈때 복원되는거 막기
        guard !isAIImportPresented else { return }
        guard let backup = originalJobBackup else { return }

        job.name = backup.name
        job.hourlyWage = backup.hourlyWage
        job.defaultDays = backup.defaultDays
        job.defaultStartTime = backup.defaultStartTime
        job.defaultEndTime = backup.defaultEndTime
        job.defaultMemo = backup.defaultMemo
        job.defaultRestTime = backup.defaultRestTime
        job.taxTypeRaw = backup.taxTypeRaw
        job.allowanceTypeRaw = backup.allowanceTypeRaw
        job.workTypeRaw = backup.workTypeRaw
        job.targetWeeklyCount = backup.targetWeeklyCount
        job.expectedDailyHours = backup.expectedDailyHours

        targetWeeklyCount = backup.targetWeeklyCount ?? 3
        expectedDailyHours = backup.expectedDailyHours ?? 5.0

        // 수정된 데이터 임시 보관
        let existingSchedules = job.regularSchedules
        // 요일별 스케줄 연결 전부 제거
        job.regularSchedules.removeAll()
        // 스케줄이 수정된 데이터 돌면서 DB에서 삭제
        for schedule in existingSchedules where schedule.modelContext != nil {
            context.delete(schedule)
        }

        // 백업된 스케줄 DB 연결
        for item in backup.regularSchedules {
            let schedule = RegularSchedule(
                dayOfWeek: item.dayOfWeek,
                startTime: item.startTime,
                endTime: item.endTime,
                breakTime: item.breakTime
            )
            schedule.workplace = job
            job.regularSchedules.append(schedule)
            if job.modelContext != nil {
                context.insert(schedule)
            }
        }

        try? context.save()
    }
}
