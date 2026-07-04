//
//  SwiftDataCalendarWorkPlaceReader.swift
//  AlbaTime
//
//  Created by 이준희 on 7/4/26.
//

import Foundation
import SwiftData

@MainActor
struct SwiftDataCalendarWorkPlaceReader: CalendarWorkPlaceReading {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchWorkPlaces() throws -> [WorkPlace] {
        let descriptor = FetchDescriptor<WorkPlace>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
