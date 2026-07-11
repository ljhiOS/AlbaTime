//
//  ScheduleResolver.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

struct ResolvedShift {
    let date: Date
    let startTime: Date
    let endTime: Date
    let breakTime: Int
    let title: String?
}

enum ScheduleResolver {
    private static func hasAIOverride(in workPlace: WorkPlace, containing date: Date) -> Bool {
        let calendar = Calendar.current
        let target = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        
        return workPlace.workSchedules.contains { workSchedule in
            guard workSchedule.isFromAIImport else { return false }
            
            let workScheduleWeekComponents = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: workSchedule.date
            )
            
            return workScheduleWeekComponents.yearForWeekOfYear == target.yearForWeekOfYear &&
            workScheduleWeekComponents.weekOfYear == target.weekOfYear
        }
    }
    
    /// [핵심 로직] 특정 날짜에 근무가 있는지 판단
    /// - 1순위: AI/수기로 저장된 기록 (무조건 최우선)
    /// - 2순위: 고정 근무 패턴 (자율 근무제는 해당 없음)
    static func resolve(
        workPlace: WorkPlace,
        for date: Date
    ) -> ResolvedShift? {
        let calendar = Calendar.current

        // 0. 캘린더에서 저장한 날짜별 실제/조정 기록이 가장 우선입니다.
        if let record = workPlace.workRecords.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) {
            return ResolvedShift(
                date: calendar.startOfDay(for: date),
                startTime: record.startTime,
                endTime: record.endTime,
                breakTime: max(0, record.breakTime),
                title: nil
            )
        }
        
        // 1. 개별 기록(AI/수기) 확인 -> 자율/고정 모두 최우선 적용
        if let actualRecord = workPlace.workSchedules.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) {
            return ResolvedShift(
                date: calendar.startOfDay(for: date),
                startTime: actualRecord.startTime,
                endTime: actualRecord.endTime,
                breakTime: max(0, actualRecord.breakTime),
                title: actualRecord.memo
            )
        }
        
        if workPlace.workType == .fixed && hasAIOverride(in: workPlace, containing: date) {
            return nil
        }
        
        // 2. 고정 근무 패턴 확인 (자율 근무는 여기서 탈락)
        if workPlace.workType == .fixed {
            let weekdayStr = date.koreanWeekday
            
            // 상세 요일 설정
            if let regular = workPlace.regularSchedules.first(where: { $0.dayOfWeek == weekdayStr }) {
                let start = combineDateAndTime(date: date, time: regular.startTime)
                var end = combineDateAndTime(date: date, time: regular.endTime)
                
                // 종료시간이 시작시간보다 빠르면 종료시간을 다음 날로 보정
                if end < start {
                    end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                }
                
                return ResolvedShift(
                    date: calendar.startOfDay(for: date),
                    startTime: start,
                    endTime: end,
                    breakTime: max(0, regular.breakTime),
                    title: nil
                )
            }
            
            // 간편 요일 설정
            if workPlace.regularSchedules.isEmpty && workPlace.defaultDays.contains(weekdayStr) {
                let start = combineDateAndTime(date: date, time: workPlace.defaultStartTime)
                var end = combineDateAndTime(date: date, time: workPlace.defaultEndTime)
                
                if end < start {
                    end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                }
                
                return ResolvedShift(
                    date: calendar.startOfDay(for: date),
                    startTime: start,
                    endTime: end,
                    breakTime: max(0, workPlace.defaultRestTime ?? 0),
                    title: nil
                )
            }
        }
        
        return nil
    }

    static func resolve(
        workPlace: WorkPlace,
        in interval: DateInterval
    ) -> [ResolvedShift] {
        let calendar = Calendar.current
        var shifts: [ResolvedShift] = []
        var day = calendar.startOfDay(for: interval.start)

        while day < interval.end {
            if let shift = resolve(workPlace: workPlace, for: day) {
                shifts.append(shift)
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = nextDay
        }

        return shifts
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
}
