//
//  JobListViewStateMapper.swift
//  AlbaTime
//
//  Created by Codex on 6/19/26.
//

import Foundation

// TODO: WorkPlace 모델 정리 이후 JobListViewState의 책임 범위 재검토

@MainActor
enum JobListViewStateMapper {
    static func makeItem(from workPlace: WorkPlace) -> JobListItemViewState {
        JobListItemViewState(
            card: makeCard(from: workPlace),
            detail: makeDetail(from: workPlace),
            editingSeed: JobEditingSeedFactory.make(from: workPlace)
        )
    }

    static func makeCard(from workPlace: WorkPlace) -> JobCardViewState {
        JobCardViewState(
            id: workPlace.id,
            name: workPlace.name,
            hourlyWage: workPlace.hourlyWage,
            isPinned: workPlace.isPinned,
            isAlarmEnabled: workPlace.isAlarmEnabled,
            scheduleSummary: scheduleSummary(for: workPlace)
        )
    }

    static func makeDetail(from workPlace: WorkPlace) -> JobDetailViewState {
        let salaryData = SalaryCalculator.calculateAccruedMonthlyPay(
            workPlaces: [workPlace],
            targetMonth: Date(),
            asOf: Date()
        )

        return JobDetailViewState(
            id: workPlace.id,
            name: workPlace.name,
            hourlyWage: workPlace.hourlyWage,
            workType: workPlace.workType,
            fixedDaysText: fixedDaysText(for: workPlace),
            defaultStartTime: workPlace.defaultStartTime,
            defaultEndTime: workPlace.defaultEndTime,
            targetWeeklyCount: workPlace.targetWeeklyCount ?? 0,
            expectedDailyHours: workPlace.expectedDailyHours ?? 0,
            defaultRestTime: workPlace.defaultRestTime,
            memo: workPlace.defaultMemo ?? "",
            totalDays: salaryData.workingDays,
            totalHours: salaryData.totalHours,
            totalWage: salaryData.totalPay
        )
    }
}

private extension JobListViewStateMapper {
    static func scheduleSummary(for workPlace: WorkPlace) -> String {
        if workPlace.workType == .flexible {
            let count = workPlace.targetWeeklyCount ?? 0
            let hours = workPlace.expectedDailyHours ?? 0
            return "주 \(count)회 / 일 평균 \(String(format: "%.1f", hours))시간"
        }

        var timeGroups: [String: Set<String>] = [:]

        for schedule in workPlace.regularSchedules {
            let time = "\(schedule.startTime.time24h) ~ \(schedule.endTime.time24h)"
            timeGroups[time, default: []].insert(schedule.dayOfWeek)
        }

        if timeGroups.isEmpty && !workPlace.defaultDays.isEmpty {
            return "\(workPlace.defaultDays): \(workPlace.defaultStartTime.time24h) ~ \(workPlace.defaultEndTime.time24h)"
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

    static func fixedDaysText(for workPlace: WorkPlace) -> String {
        let order = ["월", "화", "수", "목", "금", "토", "일"]
        let days = Array(Set(workPlace.regularSchedules.map(\.dayOfWeek)))
            .sorted { (order.firstIndex(of: $0) ?? 99) < (order.firstIndex(of: $1) ?? 99) }

        if !days.isEmpty { return days.joined(separator: "/") }

        let raw = workPlace.defaultDays.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "요일 미설정" : raw
    }
}
