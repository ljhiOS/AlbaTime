//
//  SwiftDataMonthlyRecordWriter.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation
import SwiftData

@MainActor
struct SwiftDataMonthlyRecordWriter: MonthlyRecordPersistenceWriting {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveMonthlyRecord(
        selectedDate: Date,
        amountString: String,
        existingRecords: [MonthlyRecord]
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

        try context.save()
    }

    func deleteMonthlyRecords(
        offsets: IndexSet,
        sortedRecords: [MonthlyRecord]
    ) throws {
        for index in offsets {
            guard sortedRecords.indices.contains(index) else { continue }
            context.delete(sortedRecords[index])
        }

        try context.save()
    }
}
