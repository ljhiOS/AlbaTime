//
//  DeleteMonthlyRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

enum DeleteMonthlyRecordError: LocalizedError {
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let message):
            return "월급 기록 삭제 중 오류가 발생했어요. \(message)"
        }
    }
}

struct DeleteMonthlyRecord {
    private let appWriteCoordinator = AppWriteCoordinator()

    @MainActor
    func execute(
        offsets: IndexSet,
        sortedRecords: [MonthlyRecord],
        context: ModelContext
    ) throws {
        for index in offsets {
            guard sortedRecords.indices.contains(index) else { continue }
            context.delete(sortedRecords[index])
        }

        do {
            try appWriteCoordinator.commit(context: context)
        } catch {
            throw DeleteMonthlyRecordError.deleteFailed(error.localizedDescription)
        }
    }
}
