//
//  SaveJobUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation
import SwiftData

enum SaveJobError: LocalizedError {
    case emptyName
    case invalidWage
    case missingFixedSchedule
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "매장명을 입력해주세요."
        case .invalidWage:
            return "올바른 시급을 입력해주세요."
        case .missingFixedSchedule:
            return "요일별 근무 시간 입력 또는 AI 스케줄을 인식해주세요."
        case .saveFailed(let message):
            return "저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct SaveJob {
    @MainActor
    func execute(
        job: Workplace,
        targetWeeklyCount: Int,
        expectedDailyHours: Double,
        initialDefaultRestTime: Int?,
        context: ModelContext
    ) throws {
        try validate(job: job)
        
        if job.modelContext == nil {
            context.insert(job)
        }
        
        applyBreakTime(
            job: job,
            initialDefaultRestTime: initialDefaultRestTime
        )
        
        try applyWorkType(
            job: job,
            targetWeeklyCount: targetWeeklyCount,
            expectedDailyHours: expectedDailyHours,
            context: context
        )
        
        NotificationManager.shared.refreshNotifications(for: job)
        
        do {
            try context.save()
            let workplaces = try context.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
        } catch {
            throw SaveJobError.saveFailed(error.localizedDescription)
        }
    }
    
    private func validate(job: Workplace) throws {
            if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
                throw SaveJobError.emptyName
            }

            if job.hourlyWage <= 0 {
                throw SaveJobError.invalidWage
            }
        }
    
    private func applyBreakTime(job: Workplace, initialDefaultRestTime: Int?) {
        let updatedBreakTime = max(0, job.defaultRestTime ?? 0)
        
        if job.defaultRestTime == nil {
            for schedule in job.regularSchedules {
                schedule.breakTime = 0
            }
            for schedule in job.workSchedules {
                schedule.breakTime = 0
            }
        } else if initialDefaultRestTime != job.defaultRestTime {
            let previousBreakTime = max(0, initialDefaultRestTime ?? 0)
            
            for schedule in job.regularSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
            
            for schedule in job.workSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
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
    }
    
    private func applyWorkType(
        job: Workplace,
        targetWeeklyCount: Int,
        expectedDailyHours: Double,
        context: ModelContext
    ) throws {
        if job.workType == .flexible {
            job.targetWeeklyCount = targetWeeklyCount
            job.expectedDailyHours = expectedDailyHours
            
            let schedulesToDelete = job.regularSchedules
            job.regularSchedules.removeAll()
            schedulesToDelete.forEach { context.delete($0) }
        } else {
            job.targetWeeklyCount = nil
            job.expectedDailyHours = nil
            
            if job.regularSchedules.isEmpty && job.workSchedules.isEmpty {
                throw SaveJobError.missingFixedSchedule
            }
        }
    }
}
