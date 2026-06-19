//
//  SaveFlexibleJob.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct SaveFlexibleJob {
    let writer: any JobDraftPersistenceWriting

    @MainActor
    func execute(
        editingJobID: UUID?,
        draft: JobDraft,
        initialImportedSchedules: [ScheduleDraftItem],
        initialDefaultRestTime: Int?
    ) throws {
        try writer.saveJobDraft(
            JobDraftPersistenceRequest(
                editingJobID: editingJobID,
                draft: draft,
                orderedRegularSchedules: [],
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        )
    }
}

