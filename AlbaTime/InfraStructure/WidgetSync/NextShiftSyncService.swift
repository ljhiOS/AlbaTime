import Foundation
import WidgetKit

enum NextShiftSyncService {
    private static let appGroupID = "group.com.junhee.AlbaTime"
    private static let shiftsKey = "upcomingShifts"

    static func sync(workPlaces: [WorkPlace]) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let shifts = collectUpcomingShifts(workPlaces: workPlaces)

        if let data = try? JSONEncoder().encode(shifts) {
            defaults?.set(data, forKey: shiftsKey)
        } else {
            defaults?.removeObject(forKey: shiftsKey)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "NextShiftWidget")
    }

    private static func collectUpcomingShifts(workPlaces: [WorkPlace]) -> [SharedShift] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var results: [SharedShift] = []

        for offset in 0...30 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { continue }

            for workPlace in workPlaces {
                guard let schedule = ScheduleResolver.resolve(workPlace: workPlace, for: day) else { continue }
                let start = schedule.startTime
                let end = schedule.endTime
                guard start > now else { continue }

                let hours = WorkTimeCalculator.calculate(
                    start: start,
                    end: end,
                    restTime: schedule.breakTime
                ).total
                guard hours > 0 else { continue }

                results.append(
                    SharedShift(
                        workPlaceName: workPlace.name,
                        startTimestamp: start.timeIntervalSince1970,
                        endTimestamp: end.timeIntervalSince1970,
                        plannedHours: hours
                    )
                )
            }
        }

        return results.sorted { $0.startTimestamp < $1.startTimestamp }
    }
}
