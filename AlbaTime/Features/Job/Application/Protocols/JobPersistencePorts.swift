//
//  JobPersistencePorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

// Application 계층이 Data 구현체에 요청하는 저장/수정 port 모음
// UseCase가 필요한 기능에만 의존하도록 역할별 protocol로 분리
// 실제 앱에서는 SwiftDataJobPersistenceWriter가 이 port들을 구현합니다.

import Foundation

struct JobDraftPersistenceRequest {
    
    // 수정 대상 근무지 ID
    let editingJobID: UUID?
    
    // AddJob 화면에서 편집한 근무지 기본 정보 초안
    let draft: JobDraft
    
    // 고정 근무 스케줄
    let orderedRegularSchedules: [RegularScheduleDraft]
    
    // 초기 저장된 AI 또는 수기 추가 스케줄
    let initialImportedSchedules: [ScheduleDraftItem]
    
    // 초기 기본 휴게시간
    let initialDefaultRestTime: Int?
}

struct ScheduleDraftPersistenceRequest {
    
    // 스케줄 저장할 근무지 ID
    let jobID: UUID
    
    // 스케줄 편집 초안
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

// Job 저장 기능 전체를 제공하는 구현체용 묶음 protocol
// UseCase는 이 전체 타입이 아니라 필요한 개별 port만 의존합니다.
@MainActor
protocol JobPersistenceWriting:
    JobDraftPersistenceWriting,
    ScheduleDraftPersistenceWriting,
    WorkplacePersistenceDeleting,
    WorkplaceAlarmStateWriting,
    WorkplacePinStateWriting,
    WorkplaceMemoWriting { }
