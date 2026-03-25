//
//  parsedScheduleDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct ScheduleImportDraft {
    var parsedSchedule: [ParsedSchedule]
    var presetDrafts: [TimePresetDraft]
}

extension ScheduleImportDraft {
    static func empty() -> ScheduleImportDraft {
        ScheduleImportDraft(parsedSchedule: [], presetDrafts: [])
    }
    
    static func from(_ job: Workplace) -> ScheduleImportDraft {
        ScheduleImportDraft(
            parsedSchedule: [],
            presetDrafts: job.timePresets.map {
                TimePresetDraft(
                    id: $0.id,
                    label: $0.label,
                    startTime: $0.startTime,
                    endTime: $0.endTime
                )
            }
        )
    }
}
