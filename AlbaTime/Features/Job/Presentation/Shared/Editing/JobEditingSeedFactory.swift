//
//  JobEditingSeedFactory.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

@MainActor
enum JobEditingSeedFactory {
    static func make(from workplace: Workplace) -> JobEditingSeed {
        JobEditingSeed(
            id: workplace.id,
            jobDraft: .from(workplace),
            scheduleImportDraft: .from(workplace),
            savedAIScheduleItems: ScheduleEditDraft
                .fromSavedAISchedules(job: workplace)
                .items,
            initialDefaultRestTime: workplace.defaultRestTime
        )
    }
}
