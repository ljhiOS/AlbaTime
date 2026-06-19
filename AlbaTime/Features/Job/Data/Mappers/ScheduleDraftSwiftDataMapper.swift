//
//  ScheduleDraftSwiftDataMapper.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

extension ScheduleDraftItem {
    init(workSchedule: WorkSchedule) {
        self.id = workSchedule.id
        self.originalScheduleID = workSchedule.id
        self.date = workSchedule.date
        self.startTime = workSchedule.startTime
        self.endTime = workSchedule.endTime
        self.breakTime = workSchedule.breakTime
        self.memo = workSchedule.memo
        self.source = workSchedule.isFromAIImport ? .aiImport : .manual
        self.changeState = .clean
    }
}

extension ScheduleImportDraft {
    static func from(_ job: Workplace) -> ScheduleImportDraft {
        ScheduleImportDraft(
            schedules: job.workSchedules
                .sorted {
                    if $0.date != $1.date { return $0.date < $1.date }
                    return $0.startTime < $1.startTime
                }
                .map(ScheduleDraftItem.init(workSchedule:)),
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

extension ScheduleEditDraft {
    static func fromSavedAISchedules(
        job: Workplace,
        targetWeekStart: Date? = nil
        ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            state: .existingSavedAIEdit,
            targetWeekStart: targetWeekStart,
            items: job.workSchedules
                .filter(\.isFromAIImport)
                .sorted {
                    if $0.date != $1.date { return $0.date < $1.date }
                    return $0.startTime < $1.startTime
                }
                .map(ScheduleEditItem.init(workSchedule:))
        )
    }
}
