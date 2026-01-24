//
//  CalendarViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()

    @Published var scheduleCache: [Date: [Workplace]] = [:]
    
    // 달력 날짜 생성
    func generateDaysInMonth() -> [Date?] {
        let start = currentMonth.startOfMonth()
        let daysInMonth = start.daysInMonth()
        let startDayOfWeek = start.startDayOfWeek()
        
        var days: [Date?] = []
        for _ in 0..<(startDayOfWeek - 1) { days.append(nil) }
        for i in 0..<daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: start) {
                days.append(date)
            }
        }
        return days
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }

    func updateCache(workplaces: [Workplace]) {
        let calendar = Calendar.current
        var newCache: [Date: [Workplace]] = [:]
        
        // 이번 달의 시작과 끝 날짜 구하기 (범위 필터링용)
        let startOfMonth = currentMonth.startOfMonth()
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) else { return }
        
        // 1. [자율 근무 & 개별 기록] 처리 (데이터 -> 날짜 매핑 방식)
        for job in workplaces {
            // 이번 달에 해당하는 스케줄만 필터링 (속도 향상)
            let monthSchedules = job.workSchedules.filter {
                $0.date >= startOfMonth && $0.date <= endOfMonth
            }
            
            for schedule in monthSchedules {
                let dateKey = calendar.startOfDay(for: schedule.date)
                newCache[dateKey, default: []].append(job)
            }
        }
        
        // 2. [고정 근무] 처리 (패턴 반복)
        let daysInMonth = generateDaysInMonth().compactMap { $0 }
        
        for date in daysInMonth {
            let dateKey = calendar.startOfDay(for: date)
            let weekdayStr = date.koreanWeekday
            
            for job in workplaces where job.workType == .fixed {
                // 이미 위에서 AI 스케줄로 등록된 경우(Override), 중복 추가 방지
                if let existingJobs = newCache[dateKey], existingJobs.contains(where: { $0.id == job.id }) {
                    continue
                }
                
                // 고정 스케줄 확인
                let hasFixedSchedule = job.regularSchedules.contains { $0.dayOfWeek == weekdayStr }
                let hasSimpleFixed = job.regularSchedules.isEmpty && job.defaultDays.contains(weekdayStr)
                
                if hasFixedSchedule || hasSimpleFixed {
                    newCache[dateKey, default: []].append(job)
                }
            }
        }
        
        self.scheduleCache = newCache
    }
    
    // 캐시에서 즉시 조회 (매우 빠름)
    func getScheduledWorkplaces(for date: Date, allWorkplaces: [Workplace]) -> [Workplace] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return scheduleCache[startOfDay] ?? []
    }
    
    // MARK: - Helpers (기존 로직 유지하되 안전하게)
    func getEstimatedPay(for workplace: Workplace, on date: Date) -> Int {
        guard let schedule = workplace.getSchedule(for: date) else { return 0 }
        
        let tempSchedule = WorkSchedule(
            date: date,
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            breakTime: workplace.defaultRestTime ?? 0,
            workplace: nil
        )
        return SalaryCalculator.calculateDailyPay(schedule: tempSchedule, hourlyWage: workplace.hourlyWage)
    }
    
    func getTotalEstimatedPay(for date: Date, allWorkplaces: [Workplace]) -> Int {
        let scheduled = getScheduledWorkplaces(for: date, allWorkplaces: allWorkplaces)
        return scheduled.map { getEstimatedPay(for: $0, on: date) }.reduce(0, +)
    }
    
    func getWorkTimeRange(for workplace: Workplace, on date: Date) -> String {
        if let schedule = workplace.getSchedule(for: date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            return "\(f.string(from: schedule.startTime)) - \(f.string(from: schedule.endTime))"
        }
        return "-"
    }
}
