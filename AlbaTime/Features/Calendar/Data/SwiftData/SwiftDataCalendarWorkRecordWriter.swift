//
//  SwiftDataCalendarWorkRecordWriter.swift
//  AlbaTime
//
//  Created by Codex on 7/11/26.
//

import Foundation
import SwiftData

enum CalendarWorkRecordPersistenceError: LocalizedError {
    case missingWorkPlace

    var errorDescription: String? {
        switch self {
        case .missingWorkPlace:
            return "저장할 근무지 정보가 없어요."
        }
    }
}

@MainActor
struct SwiftDataCalendarWorkRecordWriter: CalendarWorkRecordWriting {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveWorkRecord(_ command: CalendarWorkRecordCommand) throws {
        guard let workPlace = try workPlace(for: command.workPlaceID) else {
            throw CalendarWorkRecordPersistenceError.missingWorkPlace
        }

        let times = normalizedTimes(
            date: command.date,
            startTime: command.startTime,
            endTime: command.endTime
        )

        if let record = workPlace.workRecords.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: command.date)
        }) {
            record.startTime = times.start
            record.endTime = times.end
            record.breakTime = max(0, command.breakTime)
        } else {
            let record = WorkRecord(
                date: Calendar.current.startOfDay(for: command.date),
                startTime: times.start,
                endTime: times.end,
                breakTime: max(0, command.breakTime),
                workPlace: workPlace
            )
            workPlace.workRecords.append(record)
            context.insert(record)
        }

        try context.save()
        NotificationManager.shared.refreshNotifications(for: workPlace)

        let workPlaces = try context.fetch(FetchDescriptor<WorkPlace>())
        NextShiftSyncService.sync(workPlaces: workPlaces)
    }
}

private extension SwiftDataCalendarWorkRecordWriter {
    func workPlace(for id: UUID) throws -> WorkPlace? {
        var descriptor = FetchDescriptor<WorkPlace>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func normalizedTimes(
        date: Date,
        startTime: Date,
        endTime: Date
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = combineDateAndTime(date: date, time: startTime)
        var end = combineDateAndTime(date: date, time: endTime)

        if end < start {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        }

        return (start, end)
    }

    func combineDateAndTime(date: Date, time: Date) -> Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }
}
