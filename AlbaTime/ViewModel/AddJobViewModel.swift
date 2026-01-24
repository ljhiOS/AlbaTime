//
//  AddJobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class AddJobViewModel: ObservableObject {
    
    @Published var job: Workplace
    
    // UI 상태
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
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    
    // [Case 1] 신규 생성 모드
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
    }
    
    // [Case 2] 수정(Edit) 모드
    init(editingJob: Workplace) {
        self.job = editingJob // 기존 객체를 그대로 사용
        
        // 저장되어 있던 자율 근무 설정값을 UI 변수로 가져옴
        if editingJob.workType == .flexible {
            self.targetWeeklyCount = editingJob.targetWeeklyCount ?? 3
            self.expectedDailyHours = editingJob.expectedDailyHours ?? 5.0
        }
    }
    
    // MARK: - 유효성 검사 및 AI
    
    func validateAndOpenAI() {
        if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        isAIImportPresented = true
    }
    
    // AI 데이터를 수기 입력칸에 반영
    func refreshSchedulesFromAI(context: ModelContext) {
        let aiSchedules = job.workSchedules
        guard !aiSchedules.isEmpty else { return }
        
        let calendar = Calendar.current
        let weekDaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        
        // 작업 전 job이 컨텍스트에 있는지 확인
        if job.modelContext == nil {
            context.insert(job)
        }
        
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
                context.insert(newRegular)
            }
        }
        
        try? context.save()
        self.objectWillChange.send()
    }

    // MARK: - 요일별 스케줄 로직
    
    func getSchedule(for day: String) -> RegularSchedule? {
        return job.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    func toggleDay(_ day: String, context: ModelContext) {
        if job.modelContext == nil {
            context.insert(job)
        }

        if let schedule = getSchedule(for: day) {
            if let index = job.regularSchedules.firstIndex(of: schedule) {
                job.regularSchedules.remove(at: index)
            }
            context.delete(schedule)
        } else {
            let newSchedule = RegularSchedule(
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: job.defaultRestTime ?? 60
            )
            newSchedule.workplace = job
            job.regularSchedules.append(newSchedule)
            context.insert(newSchedule)
        }
    }

    // MARK: - 저장 로직 (Save)
    
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
        
        // 2. UI 상태값을 모델에 반영 및 정리
        if job.workType == .flexible {
            job.targetWeeklyCount = targetWeeklyCount
            job.expectedDailyHours = expectedDailyHours
            
            let schedulesToDelete = job.regularSchedules
            job.regularSchedules.removeAll() // 배열 먼저 비우고
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
        NotificationManager.shared.removeNotifications(for: job)
        if job.isAlarmEnabled {
            NotificationManager.shared.scheduleWorkNotification(for: job)
        }
        
        // 4. 최종 저장
        do {
            try context.save()
            return true
        } catch {
            print("저장 실패: \(error)")
            errorMessage = "저장 중 오류가 발생했습니다."
            showAlert = true
            return false
        }
    }

    // MARK: - 프리셋 (Preset)

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
    
    func resetAllDays(context: ModelContext) {
        if job.modelContext == nil { context.insert(job) }

        job.regularSchedules.forEach { context.delete($0) }
        job.regularSchedules.removeAll()
        
        let weekdays = ["월", "화", "수", "목", "금"]
        for day in weekdays {
            let schedule = RegularSchedule(
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: job.defaultRestTime ?? 60
            )
            schedule.workplace = job
            job.regularSchedules.append(schedule)
            context.insert(schedule)
        }
    }
}
