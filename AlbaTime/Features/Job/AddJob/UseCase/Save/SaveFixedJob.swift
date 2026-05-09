//
//  SaveJobUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation
import SwiftData

struct SaveFixedJob {
    let jobSaveValidator: JobSaveValidator
    let applyBreakTime: ApplyBreakTime
    let appWriteCoordinator: AppWriteCoordinator
    
    @MainActor
    func execute(
        job: Workplace,
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
        
        job.targetWeeklyCount = nil
        job.expectedDailyHours = nil
        
        try jobSaveValidator.validateFixedJob(job: job)
        
        do {
            try appWriteCoordinator.commit(context: context, affectedWorkplace: job)
        } catch {
            throw SaveJobError.saveFailed(error.localizedDescription)
        }
    }
}
