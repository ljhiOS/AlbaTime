//
//  JobFeatureComposition.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import SwiftData

// TODO: 기능 단위(AddJob, JobList, ScheduleImport) Composition 분리 검토

@MainActor
enum JobFeatureComposition {
    static func makeJobSaving(context: ModelContext) -> SaveJobUseCase {
        SaveJobUseCase(writer: makePersistenceWriter(context: context))
    }

    static func makeScheduleSaving(context: ModelContext) -> SaveScheduleUseCase {
        SaveScheduleUseCase(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkplaceDeleting(context: ModelContext) -> DeleteWorkCard {
        DeleteWorkCard(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkplacePinToggling(context: ModelContext) -> ToggleWorkplacePin {
        ToggleWorkplacePin(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkplaceAlarmToggling(context: ModelContext) -> ToggleWorkplaceAlarm {
        ToggleWorkplaceAlarm(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkplaceMemoUpdating(context: ModelContext) -> UpdateWorkplaceMemo {
        UpdateWorkplaceMemo(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkplaceSyncing() -> any WorkplaceSyncing {
        NextShiftWorkplaceSyncing()
    }

    static func sync(workplaces: [Workplace]) {
        makeWorkplaceSyncing().sync(workplaces: workplaces)
    }

    private static func makePersistenceWriter(context: ModelContext) -> SwiftDataJobPersistenceWriter {
        SwiftDataJobPersistenceWriter(context: context)
    }
}
