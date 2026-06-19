//
//  JobEditingSession.swift
//  AlbaTime
//
//  Created by 이준희 on 3/26/26.
//

import Foundation

@MainActor
final class JobEditingSession: ObservableObject {
    let editingJobID: UUID?
    let savedAIScheduleItems: [ScheduleEditItem]
    let initialDefaultRestTime: Int?

    @Published var jobDraft: JobDraft
    @Published var scheduleImportDraft: ScheduleImportDraft

    convenience init(type: WorkType) {
        self.init(seed: .new(type: type), editingJobID: nil)
    }

    init(seed: JobEditingSeed, editingJobID: UUID? = nil) {
        self.editingJobID = editingJobID
        self.savedAIScheduleItems = seed.savedAIScheduleItems
        self.initialDefaultRestTime = seed.initialDefaultRestTime
        self.jobDraft = seed.jobDraft
        self.scheduleImportDraft = seed.scheduleImportDraft
    }
}
