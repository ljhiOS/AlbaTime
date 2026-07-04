//
//  WorkPlaceDraftSwiftDataMapper.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

extension WorkPlaceDraft {
    static func from(_ workPlace: WorkPlace) -> WorkPlaceDraft {
        WorkPlaceDraft(
            name: workPlace.name,
            hourlyWage: workPlace.hourlyWage,
            defaultRestTime: workPlace.defaultRestTime ?? 0,
            defaultMemo: workPlace.defaultMemo ?? "",
            taxType: workPlace.taxType,
            allowanceType: workPlace.allowanceType,
            workType: workPlace.workType,
            targetWeeklyCount: workPlace.targetWeeklyCount ?? 3,
            expectedDailyHours: workPlace.expectedDailyHours ?? 5.0,
            regularSchedules: workPlace.regularSchedules.map {
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

