//
//  parsedScheduleDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct ScheduleImportDraft {
    var schedules: [ScheduleDraftItem]
    var presetDrafts: [TimePresetDraft]

    var parsedSchedule: [ParsedSchedule] {
        get {
            schedules.map(\.parsedSchedule)
        }
        set {
            schedules = newValue.map {
                ScheduleDraftItem(
                    parsedSchedule: $0,
                    breakTime: 0,
                    source: .aiImport
                )
            }
        }
    }
}

extension ScheduleImportDraft {
    static func empty() -> ScheduleImportDraft {
        ScheduleImportDraft(schedules: [], presetDrafts: [])
    }

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

    func makeEditDraft(
        mode: ScheduleEditMode,
        targetWeekStart: Date? = nil
    ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            mode: mode,
            targetWeekStart: targetWeekStart,
            items: schedules
        )
    }
}
