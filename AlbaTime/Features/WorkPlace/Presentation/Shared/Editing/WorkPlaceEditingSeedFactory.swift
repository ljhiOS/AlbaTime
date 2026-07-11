//
//  WorkPlaceEditingSeedFactory.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

@MainActor
enum WorkPlaceEditingSeedFactory {
    // 근무지 수정을 위해 WorkPlace로 시드를 생성합니다.
    static func make(from workPlace: WorkPlace) -> WorkPlaceEditingSeed {
        WorkPlaceEditingSeed(
            id: workPlace.id,
            workPlaceDraft: .from(workPlace),
            scheduleImportDraft: .from(workPlace),
            savedScheduleItems: ScheduleEditDraft
                .fromSavedSchedules(workPlace: workPlace)
                .items,
            initialDefaultRestTime: workPlace.defaultRestTime
        )
    }
}
