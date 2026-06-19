//
//  JobPersistencePorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct JobDraftPersistenceRequest {
    let editingJobID: UUID?
    let draft: JobDraft
    let orderedRegularSchedules: [RegularScheduleDraft]
    let initialImportedSchedules: [ScheduleDraftItem]
    let initialDefaultRestTime: Int?
}

struct ScheduleDraftPersistenceRequest {
    let jobID: UUID
    let draft: ScheduleEditDraft
}

@MainActor
protocol JobDraftPersistenceWriting {
    func saveJobDraft(_ request: JobDraftPersistenceRequest) throws
}

@MainActor
protocol ScheduleDraftPersistenceWriting {
    func saveScheduleDraft(_ request: ScheduleDraftPersistenceRequest) throws
}

@MainActor
protocol WorkplacePersistenceDeleting {
    func deleteWorkplace(id: UUID) throws
}

@MainActor
protocol WorkplaceAlarmStateWriting {
    func toggleAlarm(id: UUID) throws
}

@MainActor
protocol WorkplacePinStateWriting {
    func togglePin(id: UUID) throws
}

@MainActor
protocol WorkplaceMemoWriting {
    func updateMemo(id: UUID, memo: String) throws
}

@MainActor
protocol JobPersistenceWriting:
    JobDraftPersistenceWriting,
    ScheduleDraftPersistenceWriting,
    WorkplacePersistenceDeleting,
    WorkplaceAlarmStateWriting,
    WorkplacePinStateWriting,
    WorkplaceMemoWriting { }
