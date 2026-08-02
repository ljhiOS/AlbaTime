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
    @Environment(\.analyticsTracker) private var analyticsTracker
    let session: WorkPlaceEditingSession

    var body: some View {
        ScheduleImportView(
            session: session,
            scheduleSaving: WorkPlaceFeatureComposition.makeScheduleSaving(context: modelContext),
            analyzeScheduleImage: WorkPlaceFeatureComposition.makeScheduleImageAnalyzer(),
            analyticsTracker: analyticsTracker
        )
    }
}
