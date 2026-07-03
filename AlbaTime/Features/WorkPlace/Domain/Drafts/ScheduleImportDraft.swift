//
//  ScheduleImportDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct ScheduleImportDraft {
    var schedules: [ScheduleDraftItem]
    var presetDrafts: [TimePresetDraft]
}

extension ScheduleImportDraft {
    static func empty() -> ScheduleImportDraft {
        ScheduleImportDraft(schedules: [], presetDrafts: [])
    }

    func makeEditDraft(
        state: ScheduleEditState,
        targetWeekStart: Date? = nil
    ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            state: state,
            targetWeekStart: targetWeekStart,
            items: schedules
        )
    }
}
