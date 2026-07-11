//
//  SaveScheduleUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/3/26.
//

import Foundation

// 스케줄 편집 결과를 저장 UseCase에 전달하는 명령입니다.
enum SaveScheduleCommand {
    // 대상 근무지의 스케줄 추가/수정/삭제 내용을 저장합니다.
    case editDraft(
        workPlaceID: UUID?,
        draft: ScheduleEditDraft
    )
}

enum SaveScheduleError: LocalizedError {
    case missingWorkPlace

    var errorDescription: String? {
        switch self {
        case .missingWorkPlace:
            return "저장할 근무지 정보가 없어요."
        }
    }
}

struct SaveScheduleUseCase: ScheduleSaving {
    private let writer: any ScheduleDraftPersistenceWriting

    init(writer: any ScheduleDraftPersistenceWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(_ command: SaveScheduleCommand) throws {
        switch command {
        case .editDraft(let workPlaceID, let draft):
            guard let workPlaceID else {
                throw SaveScheduleError.missingWorkPlace
            }

            try writer.saveScheduleDraft(
                ScheduleDraftPersistenceRequest(
                    workPlaceID: workPlaceID,
                    draft: draft
                )
            )
        }
    }
}

