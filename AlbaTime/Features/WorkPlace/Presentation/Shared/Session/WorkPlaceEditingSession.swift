//
//  WorkPlaceEditingSession.swift
//  AlbaTime
//
//  Created by 이준희 on 3/26/26.
//

import Foundation

@MainActor
final class WorkPlaceEditingSession: ObservableObject {
    let editingWorkPlaceID: UUID?
    let savedScheduleItems: [ScheduleEditItem]
    let initialDefaultRestTime: Int?

    @Published var workPlaceDraft: WorkPlaceDraft
    @Published var scheduleImportDraft: ScheduleImportDraft

    convenience init(type: WorkType) {
        self.init(seed: .new(type: type), editingWorkPlaceID: nil)
    }

    init(seed: WorkPlaceEditingSeed, editingWorkPlaceID: UUID? = nil) {
        self.editingWorkPlaceID = editingWorkPlaceID
        self.savedScheduleItems = seed.savedScheduleItems
        self.initialDefaultRestTime = seed.initialDefaultRestTime
        self.workPlaceDraft = seed.workPlaceDraft
        self.scheduleImportDraft = seed.scheduleImportDraft
    }
}
