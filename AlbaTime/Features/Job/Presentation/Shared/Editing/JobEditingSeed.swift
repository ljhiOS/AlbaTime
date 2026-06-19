//
//  JobEditingSeed.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct JobEditingSeed: Identifiable, Hashable {
    let id: UUID
    let jobDraft: JobDraft
    let scheduleImportDraft: ScheduleImportDraft
    let savedAIScheduleItems: [ScheduleEditItem]
    let initialDefaultRestTime: Int?

    static func new(type: WorkType) -> JobEditingSeed {
        JobEditingSeed(
            id: UUID(),
            jobDraft: .makeNew(type: type),
            scheduleImportDraft: .empty(),
            savedAIScheduleItems: [],
            initialDefaultRestTime: nil
        )
    }

    static func == (lhs: JobEditingSeed, rhs: JobEditingSeed) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
