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
    
    @Published var job: Workplace
    
    // UI 상태 // @MainActor 속성 선언 필요
    @Published var isAIImportPresented: Bool = false // AI 스케줄 화면 이동 트리거
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // 유연 근무 UI 바인딩용 변수
    @Published var targetWeeklyCount: Int = 3
    @Published var expectedDailyHours: Double = 5.0
    
    private let initialDefaultRestTime: Int?
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    // 케이스 구분 위해서
    
    // 신규 생성 모드
    init(type: WorkType) {
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
        self.initialDefaultRestTime = nil
    }
    
    // 수정 모드
    init(editingJob: Workplace) {
        self.job = editingJob // 기존 객체를 그대로 사용
        self.initialDefaultRestTime = editingJob.defaultRestTime
        
        // 저장되어 있던 자율 근무 설정값을 UI 변수로 가져옴
        if editingJob.workType == .flexible {
            self.targetWeeklyCount = editingJob.targetWeeklyCount ?? 3
            self.expectedDailyHours = editingJob.expectedDailyHours ?? 5.0
        }
    }
    
    // MARK: - 유효성 검사 및 AI
    
    // @MainActor 속성선언 필요 메서드
    // 매장명 및 시급 유효성 검사 통과시 AI 스케줄 화면 열기
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
        
        isAIImportPresented = true
    }

    // MARK: - 요일별 스케줄 로직
    
    // 특정 요일 근무정보 있는지 확인하는 메서드
    func getSchedule(for day: String) -> RegularSchedule? {
        return job.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    // 근무 수정 요일 버튼을 위한 메서드
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
    
    // 평일 전체선택 편의기능 제공
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
    
    // 데이터 베이스 저장 -> 사실상 가장 중요한 메서드
    // @MainActor 필요 메서드
    // as-is
    // 1) Workplace는 저장 전에 name, hourlyWage 검증을 통과해야함
    // 2) defaultResrTime은 스케줄 breakTime에 전파됨(개별 수정은 최대한 보존)
    // 3) flexible 타입에서는 regularSchedule은 DB에서 삭제되야함
    // 4) fixed 타입에서는 regularSchedule 또는 WorkSchedule이 최소 1개는 필요
    // 5) 저장 성공 후 위젯 데이터는 전체 workplace를 fetch하여 재생성
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
        
        if job.defaultRestTime == nil {
            for schedule in job.regularSchedules { schedule.breakTime = 0 }
            for schedule in job.workSchedules { schedule.breakTime = 0 }
        } else if initialDefaultRestTime != job.defaultRestTime {
            let previousBreakTime = max(0, initialDefaultRestTime ?? 0)
            for schedule in job.regularSchedules where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
            for schedule in job.workSchedules where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
        } else {
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
            
            let schedulesToDelete = job.regularSchedules
            job.regularSchedules.removeAll()
            schedulesToDelete.forEach { context.delete($0) }
            
        } else {
            // 고정 근무: 자율 근무용 변수 초기화
            job.targetWeeklyCount = nil
            job.expectedDailyHours = nil
            
            // 고정 근무인데 요일 설정이 하나도 없으면 경고 (단, AI 스케줄이 있으면 통과)
            if job.regularSchedules.isEmpty && job.workSchedules.isEmpty {
                errorMessage = "요일별 근무 시간 또는 AI 스케줄을 입력해주세요."
                showAlert = true
                return false
            }
        }
        
        // 3. 알림 갱신 로직
        NotificationManager.shared.refreshNotifications(for: job)
        
        // 4. 최종 저장
        do {
            try context.save()
            let workplaces = try context.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
            return true
        } catch {
            print("저장 실패: \(error)")
            errorMessage = "저장 중 오류가 발생했습니다.\n\(error.localizedDescription)"
            showAlert = true
            return false
        }
    }
}
