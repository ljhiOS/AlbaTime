//
//  JobEditingSeed.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

// TODO: 신규 생성시 EditingSeed 이름 사용하므로 변수명 재검토 혹은 새 구조체 생성 검토

struct JobEditingSeed: Identifiable, Hashable {
    // 수정 대상 근무지 ID
    let id: UUID
    
    // 근무지 기본 정보 입력용 초안
    let jobDraft: JobDraft
    
    // AI 스케줄 초안
    let scheduleImportDraft: ScheduleImportDraft
    
    // 저장된 AI 스케줄 목록
    let savedAIScheduleItems: [ScheduleEditItem]
    
    // 수정 시작 시점의 기본 휴게시간
    let initialDefaultRestTime: Int?

    // 신규 등록시 생성입니다.
    static func new(type: WorkType) -> JobEditingSeed {
        JobEditingSeed(
            id: UUID(),
            jobDraft: .makeNew(type: type),
            scheduleImportDraft: .empty(),
            savedAIScheduleItems: [],
            initialDefaultRestTime: nil
        )
    }

    static func == (lhs: JobEditingSeed, rhs: JobEditingSeed) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
