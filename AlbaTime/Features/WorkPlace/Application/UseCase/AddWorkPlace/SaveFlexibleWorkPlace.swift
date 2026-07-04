//
//  SaveFlexibleWorkPlace.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct SaveFlexibleWorkPlace {
    let writer: any WorkPlaceDraftPersistenceWriting

    @MainActor
    func execute(
        editingWorkPlaceID: UUID?,
        draft: WorkPlaceDraft,
        initialImportedSchedules: [ScheduleDraftItem],
        initialDefaultRestTime: Int?
    ) throws {
        try writer.saveWorkPlaceDraft(
            PersistWorkPlaceDraftRequest(
                editingWorkPlaceID: editingWorkPlaceID,
                draft: draft,
                orderedRegularSchedules: [],
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        )
    }
}

