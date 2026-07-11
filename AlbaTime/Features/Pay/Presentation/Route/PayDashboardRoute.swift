//
//  PayDashboardRoute.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import SwiftData
import SwiftUI

struct PayDashboardRoute: View {
    @Query private var workPlaces: [WorkPlace]

    var body: some View {
        PayDashboardView(
            workPlaces: workPlaces,
            viewModel: PayViewModel()
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkSchedule.self,
        WorkRecord.self,
        WorkTimePreset.self,
        configurations: config
    )

    let place = WorkPlace(
        name: "GS25 강남점",
        hourlyWage: 10000,
        defaultDays: "월,수,금",
        defaultStartTime: Date(),
        defaultEndTime: Date().addingTimeInterval(3600 * 8)
    )
    container.mainContext.insert(place)

    return NavigationStack {
        PayDashboardRoute()
    }
    .modelContainer(container)
}
