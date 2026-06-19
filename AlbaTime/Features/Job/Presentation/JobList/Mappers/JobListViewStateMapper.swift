//
//  JobListViewStateMapper.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

@MainActor
enum JobListViewStateMapper {
    static func makeItem(from workplace: Workplace) -> JobListItemViewState {
        JobListItemViewState(
            card: makeCard(from: workplace),
            detail: makeDetail(from: workplace),
            editingSeed: JobEditingSeedFactory.make(from: workplace)
        )
    }

    static func makeCard(from workplace: Workplace) -> JobCardViewState {
        JobCardViewState(
            id: workplace.id,
            name: workplace.name,
            hourlyWage: workplace.hourlyWage,
            isPinned: workplace.isPinned,
            isAlarmEnabled: workplace.isAlarmEnabled,
            scheduleSummary: scheduleSummary(for: workplace)
        )
    }

    static func makeDetail(from workplace: Workplace) -> JobDetailViewState {
        let salaryData = SalaryCalculator.calculateAccruedMonthlyPay(
            workplaces: [workplace],
            targetMonth: Date(),
            asOf: Date()
        )

        return JobDetailViewState(
            id: workplace.id,
            name: workplace.name,
            hourlyWage: workplace.hourlyWage,
            workType: workplace.workType,
            fixedDaysText: fixedDaysText(for: workplace),
            defaultStartTime: workplace.defaultStartTime,
            defaultEndTime: workplace.defaultEndTime,
            targetWeeklyCount: workplace.targetWeeklyCount ?? 0,
            expectedDailyHours: workplace.expectedDailyHours ?? 0,
            defaultRestTime: workplace.defaultRestTime,
            memo: workplace.defaultMemo ?? "",
            totalDays: salaryData.workingDays,
            totalHours: salaryData.totalHours,
            totalWage: salaryData.totalPay
        )
    }
}

private extension JobListViewStateMapper {
    static func scheduleSummary(for workplace: Workplace) -> String {
        if workplace.workType == .flexible {
            let count = workplace.targetWeeklyCount ?? 0
            let hours = workplace.expectedDailyHours ?? 0
            return "주 \(count)회 / 일 평균 \(String(format: "%.1f", hours))시간"
        }

        var timeGroups: [String: Set<String>] = [:]

        for schedule in workplace.regularSchedules {
            let time = "\(schedule.startTime.time24h) ~ \(schedule.endTime.time24h)"
            timeGroups[time, default: []].insert(schedule.dayOfWeek)
        }

        if timeGroups.isEmpty && !workplace.defaultDays.isEmpty {
            return "\(workplace.defaultDays): \(workplace.defaultStartTime.time24h) ~ \(workplace.defaultEndTime.time24h)"
        }

        if timeGroups.isEmpty { return "설정된 근무가 없습니다" }

        return formatGroupsToText(timeGroups)
    }

    static func formatGroupsToText(_ groups: [String: Set<String>]) -> String {
        let dayOrder = ["월", "화", "수", "목", "금", "토", "일"]

        let sortedLines = groups.compactMap { time, daysSet -> (String, Int)? in
            let sortedDays = daysSet.sorted {
                (dayOrder.firstIndex(of: $0) ?? 99) < (dayOrder.firstIndex(of: $1) ?? 99)
            }
            guard let firstDay = sortedDays.first else { return nil }

            let sortIndex = dayOrder.firstIndex(of: firstDay) ?? 99
            return ("\(sortedDays.joined(separator: "/")): \(time)", sortIndex)
        }

        return sortedLines
            .sorted { $0.1 < $1.1 }
            .map(\.0)
            .joined(separator: "\n")
    }

    static func fixedDaysText(for workplace: Workplace) -> String {
        let order = ["월", "화", "수", "목", "금", "토", "일"]
        let days = Array(Set(workplace.regularSchedules.map(\.dayOfWeek)))
            .sorted { (order.firstIndex(of: $0) ?? 99) < (order.firstIndex(of: $1) ?? 99) }

        if !days.isEmpty { return days.joined(separator: "/") }

        let raw = workplace.defaultDays.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "요일 미설정" : raw
    }
}
