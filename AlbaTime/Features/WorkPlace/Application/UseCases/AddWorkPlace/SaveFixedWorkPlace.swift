//
//  SaveFixedWorkPlace.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

struct SaveFixedWorkPlace {
    let workPlaceSaveValidator: WorkPlaceSaveValidator
    let writer: any WorkPlaceDraftPersistenceWriting

    @MainActor
    func execute(
        editingWorkPlaceID: UUID?,
        draft: WorkPlaceDraft,
        orderedRegularSchedules: [RegularScheduleDraft],
        initialImportedSchedules: [ScheduleDraftItem],
        initialDefaultRestTime: Int?
    ) throws {
        try workPlaceSaveValidator.validateFixedWorkPlace(
            orderedRegularSchedules: orderedRegularSchedules,
            initialImportedSchedules: initialImportedSchedules
        )

        try writer.saveWorkPlaceDraft(
            PersistWorkPlaceDraftRequest(
                editingWorkPlaceID: editingWorkPlaceID,
                draft: draft,
                orderedRegularSchedules: orderedRegularSchedules,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        )
    }
}

