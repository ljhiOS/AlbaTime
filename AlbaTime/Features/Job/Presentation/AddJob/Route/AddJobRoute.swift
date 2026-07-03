//
//  AddJobRoute.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftData
import SwiftUI

struct AddJobRoute: View {
    @Environment(\.modelContext) private var modelContext
    let stateName: String
    let editingSeed: JobEditingSeed?
    let selectedType: WorkType?

    init(
        stateName: String = "근무지 등록",
        editingSeed: JobEditingSeed? = nil,
        selectedType: WorkType? = nil
    ) {
        self.stateName = stateName
        self.editingSeed = editingSeed
        self.selectedType = selectedType
    }

    var body: some View {
        AddJobView(
            stateName: stateName,
            editingSeed: editingSeed,
            selectedType: selectedType,
            jobSaving: JobFeatureComposition.makeJobSaving(context: modelContext),
            scheduleSaving: JobFeatureComposition.makeScheduleSaving(context: modelContext)
        )
    }
}

// MARK: - Preview
#Preview("고정 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return NavigationStack {
        AddJobRoute(stateName: "알바 등록", selectedType: .fixed)
    }
    .modelContainer(container)
}

#Preview("자율 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return NavigationStack {
        AddJobRoute(stateName: "알바 등록", selectedType: .flexible)
    }
    .modelContainer(container)
}
