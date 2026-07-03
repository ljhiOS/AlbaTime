//
//  ScheduleImportRoute.swift
//  AlbaTime
//
//  Created by Codex on 7/3/26.
//

import SwiftData
import SwiftUI

struct ScheduleImportRoute: View {
    @Environment(\.modelContext) private var modelContext
    let session: JobEditingSession

    var body: some View {
        ScheduleImportView(
            session: session,
            scheduleSaving: JobFeatureComposition.makeScheduleSaving(context: modelContext),
            analyzeScheduleImage: JobFeatureComposition.makeScheduleImageAnalyzer()
        )
    }
}
