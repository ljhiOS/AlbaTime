//
//  DeleteWorkPlace.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation

enum DeleteWorkPlaceError: LocalizedError {
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let message):
            return "삭제 중 오류가 발생했어요. \(message)"
        }
    }
}

struct DeleteWorkCard: WorkPlaceDeleting {
    private let writer: any WorkPlacePersistenceDeleting

    init(writer: any WorkPlacePersistenceDeleting) {
        self.writer = writer
    }

    @MainActor
    func execute(workPlaceID: UUID) throws {
        do {
            try writer.deleteWorkPlace(id: workPlaceID)
        } catch {
            throw DeleteWorkPlaceError.deleteFailed(error.localizedDescription)
        }
    }
}
