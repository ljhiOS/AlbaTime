//
//  AddWorkPlaceRoute.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftData
import SwiftUI

struct AddWorkPlaceRoute: View {
    @Environment(\.modelContext) private var modelContext
    let stateName: String
    let editingSeed: WorkPlaceEditingSeed?
    let selectedType: WorkType?

    init(
        stateName: String = "근무지 등록",
        editingSeed: WorkPlaceEditingSeed? = nil,
        selectedType: WorkType? = nil
    ) {
        self.stateName = stateName
        self.editingSeed = editingSeed
        self.selectedType = selectedType
    }

    var body: some View {
        AddWorkPlaceView(
            stateName: stateName,
            editingSeed: editingSeed,
            selectedType: selectedType,
            workPlaceSaving: WorkPlaceFeatureComposition.makeWorkPlaceSaving(context: modelContext)
        )
    }
}

// MARK: - Preview
#Preview("고정 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkSchedule.self,
        WorkRecord.self,
        WorkTimePreset.self,
        configurations: config
    )

    return NavigationStack {
        AddWorkPlaceRoute(stateName: "알바 등록", selectedType: .fixed)
    }
    .modelContainer(container)
}

#Preview("자율 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkPlace.self,
        RegularSchedule.self,
        WorkSchedule.self,
        WorkRecord.self,
        WorkTimePreset.self,
        configurations: config
    )

    return NavigationStack {
        AddWorkPlaceRoute(stateName: "알바 등록", selectedType: .flexible)
    }
    .modelContainer(container)
}
