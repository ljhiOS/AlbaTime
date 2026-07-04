//
//  MonthlyRecordProtocol.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
protocol MonthlyRecordSaving {
    func execute(
        selectedDate: Date,
        amountString: String,
        existingRecords: [MonthlyRecord]
    ) throws
}

@MainActor
protocol MonthlyRecordDeleting {
    func execute(
        offsets: IndexSet,
        sortedRecords: [MonthlyRecord]
    ) throws
}

@MainActor
protocol MonthlyRecordPersistenceWriting {
    func saveMonthlyRecord(
        selectedDate: Date,
        amountString: String,
        existingRecords: [MonthlyRecord]
    ) throws

    func deleteMonthlyRecords(
        offsets: IndexSet,
        sortedRecords: [MonthlyRecord]
    ) throws
}
