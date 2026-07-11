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
    static func from(_ workPlace: WorkPlace) -> ScheduleImportDraft {
        ScheduleImportDraft(
            schedules: workPlace.workSchedules
                .sorted {
                    if $0.date != $1.date { return $0.date < $1.date }
                    return $0.startTime < $1.startTime
                }
                .map(ScheduleDraftItem.init(workSchedule:)),
            presetDrafts: workPlace.timePresets.map {
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
    static func fromSavedSchedules(
        workPlace: WorkPlace,
        targetWeekStart: Date? = nil
        ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            state: .existingSavedScheduleEdit,
            targetWeekStart: targetWeekStart,
            items: workPlace.workSchedules
                .sorted {
                    if $0.date != $1.date { return $0.date < $1.date }
                    return $0.startTime < $1.startTime
                }
                .map(ScheduleEditItem.init(workSchedule:))
        )
    }
}
