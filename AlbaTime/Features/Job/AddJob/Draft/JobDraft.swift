//
//  JobDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct JobDraft {
    var name: String
    var hourlyWage: Int

    var defaultRestTime: Int
    var defaultMemo: String

    var taxType: TaxType
    var allowanceType: AllowanceType
    var workType: WorkType

    var targetWeeklyCount: Int
    var expectedDailyHours: Double

    var regularSchedules: [RegularScheduleDraft]

}

struct RegularScheduleDraft: Identifiable {
    let id: UUID
    var dayOfWeek: String
    var startTime: Date
    var endTime: Date
    var breakTime: Int
}

extension JobDraft {
    static func makeNew(type: WorkType) -> JobDraft {
            JobDraft(
                name: "",
                hourlyWage: 0,
                defaultRestTime: 0,
                defaultMemo: "",
                taxType: .none,
                allowanceType: .none,
                workType: type,
                targetWeeklyCount: 3,
                expectedDailyHours: 5.0,
                regularSchedules: []
            )
        }
}

extension JobDraft {
    static func from(_ job: Workplace) -> JobDraft {
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
