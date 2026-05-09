//
//  ToggleWorkplacePin.swift
//  AlbaTime
//
//  Created by Codex on 5/9/26.
//

import Foundation
import SwiftData

enum ToggleWorkplacePinError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "고정 상태 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkplacePin {
    private let appWriteCoordinator = AppWriteCoordinator()

    @MainActor
    func execute(workplace: Workplace, context: ModelContext) throws {
        do {
            workplace.isPinned.toggle()
            try appWriteCoordinator.commit(context: context)
        } catch {
            throw ToggleWorkplacePinError.saveFailed(error.localizedDescription)
        }
    }
}
