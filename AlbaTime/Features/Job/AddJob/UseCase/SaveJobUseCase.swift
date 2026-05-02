//
//  SaveJobUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation
import SwiftData

struct SaveJobUseCase {
    private let jobSaveValidator = JobSaveValidator()
    private let applyBreakTime = ApplyBreakTime()
    private let appWriteCoordinator = AppWriteCoordinator()
    
    @MainActor
    func execute(
        job: Workplace,
        targetWeeklyCount: Int,
        expectedDailyHours: Double,
        initialDefaultRestTime: Int?,
        context: ModelContext
    ) throws {
        switch job.workType {
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
                targetWeeklyCount: targetWeeklyCount,
                expectedDailyHours: expectedDailyHours,
                initialDefaultRestTime: initialDefaultRestTime,
                context: context
            )
        }
    }
}
