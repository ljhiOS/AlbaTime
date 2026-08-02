//
//  RealAchiveRecordRoute.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation
import SwiftData
import SwiftUI

struct RealAchiveRecordRoute: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsTracker) private var analyticsTracker

    @Query(
        sort: [
            SortDescriptor(\MonthlyRecord.year, order: .reverse),
            SortDescriptor(\MonthlyRecord.month, order: .reverse)
        ]
    )
    private var records: [MonthlyRecord]

    var body: some View {
        RealAchiveRecord(
            records: records,
            viewModel: RealAchiveRecordViewModel(
                monthlyRecordSaving: PayFeatureComposition.makeMonthlyRecordSaving(
                    context: modelContext
                ),
                monthlyRecordDeleting: PayFeatureComposition.makeMonthlyRecordDeleting(
                    context: modelContext
                ),
                analyticsTracker: analyticsTracker
            )
        )
    }
}

#Preview("데이터 없음") {
    NavigationStack {
        RealAchiveRecordRoute()
    }
    .modelContainer(for: MonthlyRecord.self, inMemory: true)
}

#Preview("데이터 있음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MonthlyRecord.self, configurations: config)

    let r1 = MonthlyRecord(year: 2026, month: 2, actualAmount: "1240000")
    let r2 = MonthlyRecord(year: 2026, month: 1, actualAmount: "980000")
    let r3 = MonthlyRecord(year: 2025, month: 12, actualAmount: "1115000")

    container.mainContext.insert(r1)
    container.mainContext.insert(r2)
    container.mainContext.insert(r3)

    return NavigationStack {
        RealAchiveRecordRoute()
    }
    .modelContainer(container)
}
