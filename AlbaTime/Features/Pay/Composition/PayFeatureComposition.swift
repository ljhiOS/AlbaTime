//
//  PayFeatureComposition.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import SwiftData

@MainActor
enum PayFeatureComposition {
    static func makeMonthlyRecordSaving(context: ModelContext) -> any MonthlyRecordSaving {
        SaveMonthlyRecord(writer: makeMonthlyRecordWriter(context: context))
    }

    static func makeMonthlyRecordDeleting(context: ModelContext) -> any MonthlyRecordDeleting {
        DeleteMonthlyRecord(writer: makeMonthlyRecordWriter(context: context))
    }

    private static func makeMonthlyRecordWriter(context: ModelContext) -> SwiftDataMonthlyRecordWriter {
        SwiftDataMonthlyRecordWriter(context: context)
    }
}
