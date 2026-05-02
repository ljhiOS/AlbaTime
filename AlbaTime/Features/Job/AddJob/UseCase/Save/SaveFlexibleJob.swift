//
//  SaveFlexibleJob.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

struct SaveFlexibleJob {
    let jobSaveValidator: JobSaveValidator
    let applyBreakTime: ApplyBreakTime
    let appWriteCoordinator: AppWriteCoordinator
    
    @MainActor
    func execute(
        job: Workplace,
        targetWeeklyCount: Int,
        expectedDailyHours: Double,
        initialDefaultRestTime: Int?,
        context: ModelContext
    ) throws {
        try jobSaveValidator.validate(job: job)
        
        if job.modelContext == nil {
            context.insert(job)
        }
        
        applyBreakTime.breakTime(
            job: job,
            initialDefaultRestTime: initialDefaultRestTime
        )
        
        job.targetWeeklyCount = targetWeeklyCount
        job.expectedDailyHours = expectedDailyHours
        
        let regularSchedulesToDelete = job.regularSchedules
        job.regularSchedules.removeAll()
        regularSchedulesToDelete.forEach { context.delete($0) }
        
        do {
            try appWriteCoordinator.commit(context: context, affectedWorkplace: job)
        } catch {
            throw SaveJobError.saveFailed(error.localizedDescription)
        }
    }
}
