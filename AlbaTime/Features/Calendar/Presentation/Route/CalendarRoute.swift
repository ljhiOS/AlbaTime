//
//  CalendarRoute.swift
//  AlbaTime
//
//  Created by 이준희 on 7/4/26.
//

import SwiftData
import SwiftUI

struct CalendarRoute: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsTracker) private var analyticsTracker

    var body: some View {
        CalendarView(
            viewModel: CalendarViewModel(
                loadCalendarWorkPlaces: CalendarFeatureComposition.makeLoadCalendarWorkPlaces(
                    context: modelContext
                ),
                workRecordSaving: CalendarFeatureComposition.makeWorkRecordSaving(
                    context: modelContext
                ),
                analyticsTracker: analyticsTracker
            )
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        MonthlyRecord.self,
        RegularSchedule.self,
        WorkSchedule.self,
        WorkRecord.self,
        WorkTimePreset.self,
        configurations: config
    )

    return CalendarRoute()
        .modelContainer(container)
}
