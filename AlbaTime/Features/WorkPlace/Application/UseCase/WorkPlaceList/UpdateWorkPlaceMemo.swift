//
//  UpdateWorkPlaceMemo.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

enum UpdateWorkPlaceMemoError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "메모 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct UpdateWorkPlaceMemo: WorkPlaceMemoUpdating {
    private let writer: any WorkPlaceMemoWriting

    init(writer: any WorkPlaceMemoWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workPlaceID: UUID, memo: String) throws {
        do {
            try writer.updateMemo(id: workPlaceID, memo: memo)
        } catch {
            throw UpdateWorkPlaceMemoError.saveFailed(error.localizedDescription)
        }
    }
}
