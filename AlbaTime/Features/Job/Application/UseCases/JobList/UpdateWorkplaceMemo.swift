//
//  UpdateWorkplaceMemo.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

enum UpdateWorkplaceMemoError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "메모 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct UpdateWorkplaceMemo: WorkplaceMemoUpdating {
    private let writer: any WorkplaceMemoWriting

    init(writer: any WorkplaceMemoWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workplaceID: UUID, memo: String) throws {
        do {
            try writer.updateMemo(id: workplaceID, memo: memo)
        } catch {
            throw UpdateWorkplaceMemoError.saveFailed(error.localizedDescription)
        }
    }
}
