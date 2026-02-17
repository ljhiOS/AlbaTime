//
//  NextShiftTimelineProvider.swift
//  AlbaTime
//
//  Created by 이준희 on 2/6/26.
//

import WidgetKit
import Foundation

struct NextShiftTimelineProvider: TimelineProvider {
    private let repository = UserDefaultsNextShiftWidgetRepository()

    func placeholder(in context: Context) -> NextShiftWidgetEntry {
        NextShiftWidgetEntry(
            model: WidgetModel(
                workplaceName: "GS25 강남점",
                shiftStart: Calendar.current.date(byAdding: .hour, value: 4, to: Date()),
                shiftEnd: Calendar.current.date(byAdding: .hour, value: 8, to: Date()),
                plannedHours: 4.0
            ),
            date: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextShiftWidgetEntry) -> Void) {
        completion(NextShiftWidgetEntry(model: repository.read(), date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextShiftWidgetEntry>) -> Void) {
        let now = Date()
        let upcoming = repository.readUpcoming()
        var entries: [NextShiftWidgetEntry] = []

        let emptyModel = WidgetModel(workplaceName: "근무 없음", shiftStart: nil, shiftEnd: nil, plannedHours: nil)
        let currentModel = upcoming.first ?? emptyModel
        entries.append(NextShiftWidgetEntry(model: currentModel, date: now))

        // At each upcoming shift start, switch widget content to "the next upcoming shift after that start".
        for (idx, shift) in upcoming.prefix(24).enumerated() {
            guard let start = shift.shiftStart, start > now else { continue }

            let nextModel = upcoming.dropFirst(idx + 1).first ?? emptyModel
            entries.append(NextShiftWidgetEntry(model: nextModel, date: start))
        }

        if entries.count == 1 {
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
            completion(Timeline(entries: entries, policy: .after(refreshDate)))
            return
        }

        entries.sort { $0.date < $1.date }
        // Remove duplicated timeline points if two shifts share the same start time.
        var uniqueEntries: [NextShiftWidgetEntry] = []
        for entry in entries {
            if let last = uniqueEntries.last,
               abs(last.date.timeIntervalSince(entry.date)) < 1 {
                uniqueEntries[uniqueEntries.count - 1] = entry
            } else {
                uniqueEntries.append(entry)
            }
        }

        completion(Timeline(entries: uniqueEntries, policy: .atEnd))
    }
}
