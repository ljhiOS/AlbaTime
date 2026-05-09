//
//  DeleteWorkplace.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation
import SwiftData

enum DeleteWorkplaceError: LocalizedError {
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let message):
            return "삭제 중 오류가 발생했어요. \(message)"
        }
    }
}

struct DeleteWorkCard {
    private let appWriteCoordinator = AppWriteCoordinator()

    @MainActor
    func execute(workplace: Workplace, context: ModelContext) throws {
        do {
            try appWriteCoordinator.delete(workplace: workplace, context: context)
        } catch {
            throw DeleteWorkplaceError.deleteFailed(error.localizedDescription)
        }
    }
}
