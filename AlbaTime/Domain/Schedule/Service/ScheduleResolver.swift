//
//  ScheduleResolver.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

enum ScheduleResolver {
    static func hasAIOverride(in workPlace: WorkPlace, containing date: Date) -> Bool {
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
    ) -> (startTime: Date, endTime: Date, title: String?)? {
        let calendar = Calendar.current
        
        // 1. 개별 기록(AI/수기) 확인 -> 자율/고정 모두 최우선 적용
        if let actualRecord = workPlace.workSchedules.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) {
            return (actualRecord.startTime, actualRecord.endTime, actualRecord.memo)
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
                
                return (start, end, nil)
            }
            
            // 간편 요일 설정
            if workPlace.regularSchedules.isEmpty && workPlace.defaultDays.contains(weekdayStr) {
                let start = combineDateAndTime(date: date, time: workPlace.defaultStartTime)
                var end = combineDateAndTime(date: date, time: workPlace.defaultEndTime)
                
                if end < start {
                    end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                }
                
                return (start, end, nil)
            }
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
}
