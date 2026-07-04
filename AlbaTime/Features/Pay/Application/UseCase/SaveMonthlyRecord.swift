//
//  SaveMonthlyRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

enum SaveMonthlyRecordError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "월급 기록 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct SaveMonthlyRecord: MonthlyRecordSaving {
    private let writer: any MonthlyRecordPersistenceWriting

    init(writer: any MonthlyRecordPersistenceWriting) {
        self.writer = writer
    }

    func execute(
        selectedDate: Date,
        amountString: String,
        existingRecords: [MonthlyRecord]
    ) throws {
        do {
            try writer.saveMonthlyRecord(
                selectedDate: selectedDate,
                amountString: amountString,
                existingRecords: existingRecords
            )
        } catch {
            throw SaveMonthlyRecordError.saveFailed(error.localizedDescription)
        }
    }
}
