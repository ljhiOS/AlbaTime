//
//  SaveMonthlyRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

enum SaveMonthlyRecordError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "월급 기록 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct SaveMonthlyRecord {
    private let appWriteCoordinator = AppWriteCoordinator()

    @MainActor
    func execute(
        selectedDate: Date,
        amountString: String,
        existingRecords: [MonthlyRecord],
        context: ModelContext
    ) throws {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)

        if let existingRecord = existingRecords.first(where: { $0.year == year && $0.month == month }) {
            existingRecord.actualAmount = amountString
        } else {
            let newRecord = MonthlyRecord(
                year: year,
                month: month,
                actualAmount: amountString
            )
            context.insert(newRecord)
        }

        do {
            try appWriteCoordinator.commit(context: context)
        } catch {
            throw SaveMonthlyRecordError.saveFailed(error.localizedDescription)
        }
    }
}
