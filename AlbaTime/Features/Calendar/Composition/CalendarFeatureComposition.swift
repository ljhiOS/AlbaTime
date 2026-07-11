//
//  CalendarFeatureComposition.swift
//  AlbaTime
//
//  Created by 이준희 on 7/4/26.
//

import SwiftData

@MainActor
enum CalendarFeatureComposition {
    static func makeLoadCalendarWorkPlaces(context: ModelContext) -> LoadCalendarWorkPlaces {
        LoadCalendarWorkPlaces(
            reader: SwiftDataCalendarWorkPlaceReader(context: context)
        )
    }

    static func makeWorkRecordSaving(context: ModelContext) -> SaveCalendarWorkRecord {
        SaveCalendarWorkRecord(
            writer: SwiftDataCalendarWorkRecordWriter(context: context)
        )
    }
}
