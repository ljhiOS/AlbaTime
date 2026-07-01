//
//  SaveScheduleUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/3/26.
//

import Foundation

enum SaveScheduleCommand {
    case editDraft(
        jobID: UUID?,
        draft: ScheduleEditDraft
    )
}

enum SaveScheduleError: LocalizedError {
    case missingJob

    var errorDescription: String? {
        switch self {
        case .missingJob:
            return "저장할 근무지 정보가 없습니다."
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
        case .editDraft(let jobID, let draft):
            guard let jobID else {
                throw SaveScheduleError.missingJob
            }

            try writer.saveScheduleDraft(
                ScheduleDraftPersistenceRequest(
                    jobID: jobID,
                    draft: draft
                )
            )
        }
    }
}

