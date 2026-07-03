//
//  JobDraftSwiftDataMapper.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

extension JobDraft {
    static func from(_ job: WorkPlace) -> JobDraft {
        JobDraft(
            name: job.name,
            hourlyWage: job.hourlyWage,
            defaultRestTime: job.defaultRestTime ?? 0,
            defaultMemo: job.defaultMemo ?? "",
            taxType: job.taxType,
            allowanceType: job.allowanceType,
            workType: job.workType,
            targetWeeklyCount: job.targetWeeklyCount ?? 3,
            expectedDailyHours: job.expectedDailyHours ?? 5.0,
            regularSchedules: job.regularSchedules.map {
                RegularScheduleDraft(
                    id: $0.id,
                    dayOfWeek: $0.dayOfWeek,
                    startTime: $0.startTime,
                    endTime: $0.endTime,
                    breakTime: $0.breakTime
                )
            }
        )
    }
}

