//
//  JobListRoute.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftData
import SwiftUI

struct JobListRoute: View {
    @Query(sort: \Workplace.createdAt, order: .reverse) private var workplaces: [Workplace]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        JobListView(
            pinnedJobs: items(from: workplaces.filter(\.isPinned)),
            normalJobs: items(from: workplaces.filter { !$0.isPinned }),
            viewModel: JobListViewModel(
                workplaceDeleting: JobFeatureComposition.makeWorkplaceDeleting(context: modelContext),
                alarmToggling: JobFeatureComposition.makeWorkplaceAlarmToggling(context: modelContext),
                pinToggling: JobFeatureComposition.makeWorkplacePinToggling(context: modelContext),
                memoUpdating: JobFeatureComposition.makeWorkplaceMemoUpdating(context: modelContext)
            ),
            onAppear: {
                JobFeatureComposition.sync(workplaces: workplaces)
            }
        )
    }

    private func items(from workplaces: [Workplace]) -> [JobListItemViewState] {
        workplaces.map { JobListViewStateMapper.makeItem(from: $0) }
    }
}

#Preview("데이터 없음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return JobListRoute()
        .modelContainer(container)
}

#Preview("데이터있음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    let sample = Workplace(
        name: "자울 테스트",
        hourlyWage: 10320,
        defaultDays: "월/화/수/목/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        workType: .fixed
    )
    container.mainContext.insert(sample)

    return JobListRoute()
        .modelContainer(container)
}
