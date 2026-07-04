//
//  SettingRoute.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import SwiftData
import SwiftUI

struct SettingRoute: View {
    @Query private var workPlaces: [WorkPlace]

    var body: some View {
        SettingView(
            workPlaces: workPlaces,
            accountViewModel: AccountDetailViewModel(
                appAlarmToggling: SettingFeatureComposition.makeAppAlarmToggling()
            )
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return NavigationStack {
        SettingRoute()
    }
    .modelContainer(container)
}
