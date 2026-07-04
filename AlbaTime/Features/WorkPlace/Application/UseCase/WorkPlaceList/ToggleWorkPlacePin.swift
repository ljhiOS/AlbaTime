//
//  ToggleWorkPlacePin.swift
//  AlbaTime
//
//  Created by Codex on 5/9/26.
//

import Foundation

enum ToggleWorkPlacePinError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "고정 상태 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkPlacePin: WorkPlacePinToggling {
    private let writer: any WorkPlacePinStateWriting

    init(writer: any WorkPlacePinStateWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workPlaceID: UUID) throws {
        do {
            try writer.togglePin(id: workPlaceID)
        } catch {
            throw ToggleWorkPlacePinError.saveFailed(error.localizedDescription)
        }
    }
}
