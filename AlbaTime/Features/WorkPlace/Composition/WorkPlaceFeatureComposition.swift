//
//  WorkPlaceFeatureComposition.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import SwiftData

// TODO: 기능 단위(AddWorkPlace, WorkPlaceList, ScheduleImport) Composition 분리 검토

// ViewModel은 UseCase Protocol에만 의존하고
// Composition에서 UseCase와 SwiftDataWriter 조립해 주입한다.
@MainActor
enum WorkPlaceFeatureComposition {
    static func makeWorkPlaceSaving(context: ModelContext) -> SaveWorkPlaceUseCase {
        SaveWorkPlaceUseCase(writer: makePersistenceWriter(context: context))
    }

    static func makeScheduleSaving(context: ModelContext) -> SaveScheduleUseCase {
        SaveScheduleUseCase(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkPlaceDeleting(context: ModelContext) -> DeleteWorkCard {
        DeleteWorkCard(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkPlacePinToggling(context: ModelContext) -> ToggleWorkPlacePin {
        ToggleWorkPlacePin(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkPlaceAlarmToggling(context: ModelContext) -> ToggleWorkPlaceAlarm {
        ToggleWorkPlaceAlarm(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkPlaceMemoUpdating(context: ModelContext) -> UpdateWorkPlaceMemo {
        UpdateWorkPlaceMemo(writer: makePersistenceWriter(context: context))
    }

    static func makeWorkPlaceSyncing() -> any WorkPlaceSyncing {
        NextShiftWorkPlaceSyncing()
    }
    
    static func makeScheduleImageAnalyzer() -> any ScheduleImageAnalyzing {
        AnalyzeScheduleImage(
            textRecognizer: OCRScheduleImageTextRecognizer(),
            textParser: ScheduleParserWorkPlaceAdapter()
        )
    }

    static func sync(workPlaces: [WorkPlace]) {
        makeWorkPlaceSyncing().sync(workPlaces: workPlaces)
    }

    private static func makePersistenceWriter(context: ModelContext) -> SwiftDataWorkPlacePersistenceWriter {
        SwiftDataWorkPlacePersistenceWriter(context: context)
    }
}
