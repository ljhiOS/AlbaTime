//
//  JobEditingSeedFactory.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

@MainActor
enum JobEditingSeedFactory {
    // 근무지 수정을 위해 WorkPlace로 시드를 생성합니다.
    static func make(from workPlace: WorkPlace) -> JobEditingSeed {
        JobEditingSeed(
            id: workPlace.id,
            jobDraft: .from(workPlace),
            scheduleImportDraft: .from(workPlace),
            savedAIScheduleItems: ScheduleEditDraft
                .fromSavedAISchedules(job: workPlace)
                .items,
            initialDefaultRestTime: workPlace.defaultRestTime
        )
    }
}
