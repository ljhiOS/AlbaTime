//
//  WorkPlaceListRoute.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftData
import SwiftUI

struct WorkPlaceListRoute: View {
    @Query(sort: \WorkPlace.createdAt, order: .reverse) private var workPlaces: [WorkPlace]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WorkPlaceListView(
            pinnedWorkPlaces: items(from: workPlaces.filter(\.isPinned)),
            normalWorkPlaces: items(from: workPlaces.filter { !$0.isPinned }),
            viewModel: WorkPlaceListViewModel(
                workPlaceDeleting: WorkPlaceFeatureComposition.makeWorkPlaceDeleting(context: modelContext),
                alarmToggling: WorkPlaceFeatureComposition.makeWorkPlaceAlarmToggling(context: modelContext),
                pinToggling: WorkPlaceFeatureComposition.makeWorkPlacePinToggling(context: modelContext),
                memoUpdating: WorkPlaceFeatureComposition.makeWorkPlaceMemoUpdating(context: modelContext)
            ),
            onAppear: {
                WorkPlaceFeatureComposition.sync(workPlaces: workPlaces)
            }
        )
    }

    private func items(from workPlaces: [WorkPlace]) -> [WorkPlaceListItemViewState] {
        return workPlaces.map { WorkPlaceListViewStateMapper.makeItem(from: $0) }
    }
}

#Preview("데이터 없음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return WorkPlaceListRoute()
        .modelContainer(container)
}

#Preview("데이터있음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    let sample = WorkPlace(
        name: "자울 테스트",
        hourlyWage: 10320,
        defaultDays: "월/화/수/목/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        workType: .fixed
    )
    container.mainContext.insert(sample)

    return WorkPlaceListRoute()
        .modelContainer(container)
}
