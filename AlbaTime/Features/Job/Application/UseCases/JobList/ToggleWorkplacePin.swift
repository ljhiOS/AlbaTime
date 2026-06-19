//
//  ToggleWorkplacePin.swift
//  AlbaTime
//
//  Created by Codex on 5/9/26.
//

import Foundation

enum ToggleWorkplacePinError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "고정 상태 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkplacePin: WorkplacePinToggling {
    private let writer: any WorkplacePinStateWriting

    init(writer: any WorkplacePinStateWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workplaceID: UUID) throws {
        do {
            try writer.togglePin(id: workplaceID)
        } catch {
            throw ToggleWorkplacePinError.saveFailed(error.localizedDescription)
        }
    }
}
