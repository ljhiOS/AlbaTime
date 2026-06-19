//
//  DeleteWorkplace.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation

enum DeleteWorkplaceError: LocalizedError {
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let message):
            return "삭제 중 오류가 발생했어요. \(message)"
        }
    }
}

struct DeleteWorkCard: WorkplaceDeleting {
    private let writer: any WorkplacePersistenceDeleting

    init(writer: any WorkplacePersistenceDeleting) {
        self.writer = writer
    }

    @MainActor
    func execute(workplaceID: UUID) throws {
        do {
            try writer.deleteWorkplace(id: workplaceID)
        } catch {
            throw DeleteWorkplaceError.deleteFailed(error.localizedDescription)
        }
    }
}
