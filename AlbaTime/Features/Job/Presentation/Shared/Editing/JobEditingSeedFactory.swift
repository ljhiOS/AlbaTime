//
//  JobEditingSeedFactory.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

@MainActor
enum JobEditingSeedFactory {
    // 근무지 수정을 위해 Workplace로 시드를 생성합니다.
    static func make(from workplace: Workplace) -> JobEditingSeed {
        JobEditingSeed(
            id: workplace.id,
            jobDraft: .from(workplace),
            scheduleImportDraft: .from(workplace),
            savedAIScheduleItems: ScheduleEditDraft
                .fromSavedAISchedules(job: workplace)
                .items,
            initialDefaultRestTime: workplace.defaultRestTime
        )
    }
}
