//
//  AddJobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor // UI 변경점에 대한 뷰 업데이트 메인스레드에서 할것임을 보장
// 향후 코드 확장시 발생가능한 스레드 안전성 실수 방지 및 뷰와 데이터 바인딩과정에서 발생할수있는 버그 컴파일타임에 차단
class AddJobViewModel: ObservableObject {
    
    @Published var job: Workplace
    
    // UI 상태 // @MainActor 속성 선언 필요
    @Published var isAIImportPresented: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // 프리셋 입력용
    @Published var isAddingPreset: Bool = false
    @Published var newPresetLabel: String = ""
    @Published var newPresetStart: Date = Date.makeTime(9, 0)
    @Published var newPresetEnd: Date = Date.makeTime(18, 0)
    
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
    func validateAndOpenAI() {
        if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        isAIImportPresented = true
    }
    
    // AI 데이터를 요일 데이터 변경 및 화면(WorkCard) 자동입력을 위한 메서드
    func refreshSchedulesFromAI(context: ModelContext) {
        let aiSchedules = job.workSchedules
        guard !aiSchedules.isEmpty else { return } // 같은 데이터 쌓이는 것 방지
        
        let calendar = Calendar.current
        let weekDaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        
        for schedule in aiSchedules {
            let weekdayIndex = calendar.component(.weekday, from: schedule.date) - 1
            let dayName = weekDaySymbols[weekdayIndex]
            
            if let existingRegular = job.regularSchedules.first(where: { $0.dayOfWeek == dayName }) {
                existingRegular.startTime = schedule.startTime
                existingRegular.endTime = schedule.endTime
                existingRegular.breakTime = schedule.breakTime
            } else {
                let newRegular = RegularSchedule(
                    dayOfWeek: dayName,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    breakTime: schedule.breakTime
                )
                newRegular.workplace = job
                job.regularSchedules.append(newRegular)
                
                if job.modelContext != nil {
                    context.insert(newRegular)
                }
            }
        }
        
        // 이미 저장된 job만 즉시 save
        if job.modelContext != nil {
            do { try context.save() }
            catch {
                errorMessage = "저장에 실패했어요. 잠시 후 다시 시도해주세요."
                showAlert = true
            }
        }
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

    // MARK: - 프리셋 (Preset)
    // UX 고려를 위한 메서드들 스케줄 표는 시간이 아닌 오픈 마감 같은 글자로 적혀있을 수 있음
    // 따라서 미리 오픈 마감 등의 단어 및 시간을 입력하여 OCR 엔진이 등록된 글자를 읽을 수 있도록 설정
    func addNewPreset() {
        guard !newPresetLabel.isEmpty else { return }
        let preset = WorkTimePreset(label: newPresetLabel, startTime: newPresetStart, endTime: newPresetEnd)
        preset.workplace = job
        job.timePresets.append(preset)
        newPresetLabel = ""
        isAddingPreset = false
    }
    
    func deletePreset(_ preset: WorkTimePreset) {
        if let index = job.timePresets.firstIndex(of: preset) {
            job.timePresets.remove(at: index)
        }
    }
}
