//
//  DeleteMonthlyRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

enum DeleteMonthlyRecordError: LocalizedError {
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let message):
            return "월급 기록 삭제 중 오류가 발생했어요. \(message)"
        }
    }
}

struct DeleteMonthlyRecord: MonthlyRecordDeleting {
    private let writer: any MonthlyRecordPersistenceWriting

    init(writer: any MonthlyRecordPersistenceWriting) {
        self.writer = writer
    }

    func execute(
        offsets: IndexSet,
        sortedRecords: [MonthlyRecord]
    ) throws {
        do {
            try writer.deleteMonthlyRecords(
                offsets: offsets,
                sortedRecords: sortedRecords
            )
        } catch {
            throw DeleteMonthlyRecordError.deleteFailed(error.localizedDescription)
        }
    }
}
