//
//  SaveFixedJob.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

struct SaveFixedJob {
    let jobSaveValidator: JobSaveValidator
    let writer: any JobDraftPersistenceWriting

    @MainActor
    func execute(
        editingJobID: UUID?,
        draft: JobDraft,
        orderedRegularSchedules: [RegularScheduleDraft],
        initialImportedSchedules: [ScheduleDraftItem],
        initialDefaultRestTime: Int?
    ) throws {
        try jobSaveValidator.validateFixedJob(
            orderedRegularSchedules: orderedRegularSchedules,
            initialImportedSchedules: initialImportedSchedules
        )

        try writer.saveJobDraft(
            JobDraftPersistenceRequest(
                editingJobID: editingJobID,
                draft: draft,
                orderedRegularSchedules: orderedRegularSchedules,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        )
    }
}

