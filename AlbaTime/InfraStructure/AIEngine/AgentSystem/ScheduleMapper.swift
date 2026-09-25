//
//  ScheduleMapper.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import Foundation

@available(iOS 27.0, *)
struct ScheduleMapper {
    func mapping(
        aiSchedules: AIScheduleExtraction,
        presets: [AgentSchedulePreset],
        referenceDate: Date
    ) -> [ParsedSchedule] {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: referenceDate)
        guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }

        var seen = Set<String>()
        return aiSchedules.schedules.compactMap { aiSchedule in
            guard let schedule = makeParsedSchedule(from: aiSchedule, presets: presets),
                  schedule.date >= weekStart, schedule.date < nextWeek else { return nil }
            return schedule
        }
        .sorted { $0.startTime < $1.startTime }
        .filter {
            seen.insert("\($0.startTime.timeIntervalSince1970)_\($0.endTime.timeIntervalSince1970)").inserted
        }
    }

    private func makeParsedSchedule(
        from aiSchedule: AISchedule,
        presets: [AgentSchedulePreset]
    ) -> ParsedSchedule? {
        let label = aiSchedule.workLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let preset: AgentSchedulePreset?
        if let label, !label.isEmpty {
            preset = presets.first { normalized($0.label) == normalized(label) }
        } else {
            preset = nil
        }
        let startValue = aiSchedule.startTime?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endValue = aiSchedule.endTime?.trimmingCharacters(in: .whitespacesAndNewlines)

        let times: (start: String, end: String)
        if let startValue, !startValue.isEmpty, let endValue, !endValue.isEmpty {
            times = (startValue, endValue)
        } else if (startValue ?? "").isEmpty, (endValue ?? "").isEmpty, let preset {
            times = (preset.startTime, preset.endTime)
        } else {
            return nil
        }

        guard let date = parseDate(aiSchedule.date),
              let startTime = parseTime(times.start, on: date),
              var endTime = parseTime(times.end, on: date, allowsEndOfDay: true),
              startTime != endTime
        else {
            return nil
        }

        if endTime < startTime {
            guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endTime) else {
                return nil
            }
            endTime = nextDay
        }

        // The payroll calculator treats identical clock times as zero hours.
        let calendar = Calendar.current
        guard calendar.component(.hour, from: startTime) != calendar.component(.hour, from: endTime)
                || calendar.component(.minute, from: startTime) != calendar.component(.minute, from: endTime)
        else { return nil }

        return ParsedSchedule(
            date: date,
            startTime: startTime,
            endTime: endTime,
            workLabel: preset?.label ?? (label?.isEmpty == false ? label : nil)
        )
    }

    private func parseDate(_ date: String) -> Date? {
        let value = date.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return nil
        }
        return Date.parse(value, format: "yyyy-MM-dd")
    }

    private func normalized(_ value: String) -> String {
        value.uppercased().filter { !$0.isWhitespace }
    }

    private func parseTime(_ value: String, on date: Date, allowsEndOfDay: Bool = false) -> Date? {
        let components = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":", omittingEmptySubsequences: false)

        guard components.count == 2,
              components[0].count == 2,
              components[1].count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              (0...59).contains(minute)
        else {
            return nil
        }

        let calendar = Calendar.current
        if allowsEndOfDay && hour == 24 && minute == 0 {
            return calendar.date(byAdding: .day, value: 1, to: date)
        }

        guard (0...23).contains(hour),
              let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date),
              calendar.isDate(time, inSameDayAs: date),
              calendar.component(.hour, from: time) == hour,
              calendar.component(.minute, from: time) == minute
        else {
            return nil
        }

        return time
    }
}
