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

            for job in workPlaces {
                guard let schedule = resolvedShift(for: job, day: day) else { continue }
                let start = schedule.start
                let end = schedule.end
                guard start > now else { continue }

                let hours = plannedHours(job: job, day: day, start: start, end: end)
                guard hours > 0 else { continue }

                results.append(
                    SharedShift(
                        workPlaceName: job.name,
                        startTimestamp: start.timeIntervalSince1970,
                        endTimestamp: end.timeIntervalSince1970,
                        plannedHours: hours
                    )
                )
            }
        }

        return results.sorted { $0.startTimestamp < $1.startTimestamp }
    }

    private static func resolvedShift(for job: WorkPlace, day: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current

        // 1) 저장된 개별 스케줄이 있으면 우선 사용
        if let actual = job.workSchedules.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            let start = combineDateAndTime(date: day, time: actual.startTime)
            var end = combineDateAndTime(date: day, time: actual.endTime)
            if end < start {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }

            // 비정상(0분) 데이터는 고정 근무일 때만 패턴으로 fallback
            if end > start {
                return (start, end)
            } else if job.workType != .fixed {
                return nil
            }
        }

        // 2) 고정 근무는 패턴(regular/default)에서 계산
        guard job.workType == .fixed else { return nil }
        let weekday = day.koreanWeekday

        if let regular = job.regularSchedules.first(where: { $0.dayOfWeek == weekday }) {
            let start = combineDateAndTime(date: day, time: regular.startTime)
            var end = combineDateAndTime(date: day, time: regular.endTime)
            if end < start {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }
            return end > start ? (start, end) : nil
        }

        if job.regularSchedules.isEmpty && job.defaultDays.contains(weekday) {
            let start = combineDateAndTime(date: day, time: job.defaultStartTime)
            var end = combineDateAndTime(date: day, time: job.defaultEndTime)
            if end < start {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }
            return end > start ? (start, end) : nil
        }

        return nil
    }

    private static func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComp.hour ?? 0,
            minute: timeComp.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }

    private static func plannedHours(job: WorkPlace, day: Date, start: Date, end: Date) -> Double {
        let calendar = Calendar.current
        var endDate = end
        if endDate < start {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        let rawHours = endDate.timeIntervalSince(start) / 3600.0
        return (max(0, rawHours) * 10).rounded() / 10
    }

}
