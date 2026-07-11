//
//  MonthlySalaryCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import Foundation

struct MonthlySalaryCalculator {
    // 기준 시점까지 종료된 근무만 계산합니다.
    static func accruedMonthlyPay(
        workPlaces: [WorkPlace],
        targetMonth: Date,
        asOf: Date = Date()
    ) -> SalaryBreakdown {
        var grandTotal = SalaryBreakdown.empty
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: targetMonth) else { return .empty }
        let startOfMonth = monthInterval.start
        let endOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        let cutoffDate = min(asOf, endOfMonth)
        let cutoffDay = calendar.startOfDay(for: cutoffDate)
        
        for workPlace in workPlaces {
            var workPlaceBreakdown = SalaryBreakdown.empty
            var weeklyHours = WeeklyHolidayAllowanceCalculator.makeBucket()
            
            var day = startOfMonth
            while day <= cutoffDay {
                if let schedule = ScheduleResolver.resolve(workPlace: workPlace, for: day) {
                    let start = schedule.startTime
                    var end = schedule.endTime
                    if end < start {
                        end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                    }
                    
                    guard end <= cutoffDate else {
                        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                            break
                        }
                        day = nextDay
                        continue
                    }
                    
                    let worked = WorkTimeCalculator.calculate(
                        start: start,
                        end: end,
                        restTime: schedule.breakTime
                    )
                    workPlaceBreakdown.add(
                        PayAmountCalculator.payFromHours(
                            hours: worked,
                            hourlyWage: workPlace.hourlyWage,
                            includeNightAllowance: workPlace.allowanceType.includesNight
                        )
                    )
                    WeeklyHolidayAllowanceCalculator.addHours(
                        worked.total,
                        on: day,
                        calendar: calendar,
                        to: &weeklyHours
                    )
                }
                
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                    break
                }
                day = nextDay
            }
            
            applyHolidayPayIfNeeded(
                to: &workPlaceBreakdown,
                workPlace: workPlace,
                weeklyHours: weeklyHours
            )
            PayAmountCalculator.applyFinalPay(to: &workPlaceBreakdown, taxType: workPlace.taxType)
            grandTotal.add(workPlaceBreakdown)
        }
        
        return grandTotal
    }
    
    // 월 전체 급여를 계산합니다.
    static func totalMonthlyPay(workPlaces: [WorkPlace], targetMonth: Date) -> SalaryBreakdown {
        var grandTotal = SalaryBreakdown.empty
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: targetMonth) else { return .empty }
        
        for workPlace in workPlaces {
            var workPlaceBreakdown = SalaryBreakdown.empty
            var weeklyHours = WeeklyHolidayAllowanceCalculator.makeBucket()

            let resolvedShifts = ScheduleResolver.resolve(
                workPlace: workPlace,
                in: monthInterval
            )

            for shift in resolvedShifts {
                addResolvedShiftPay(
                    shift: shift,
                    hourlyWage: workPlace.hourlyWage,
                    includeNightAllowance: workPlace.allowanceType.includesNight,
                    calendar: calendar,
                    breakdown: &workPlaceBreakdown,
                    weeklyHours: &weeklyHours
                )
            }

            if workPlace.workType == .flexible {
                addFlexibleForecastPay(
                    workPlace: workPlace,
                    resolvedShifts: resolvedShifts,
                    targetMonth: targetMonth,
                    calendar: calendar,
                    breakdown: &workPlaceBreakdown,
                    weeklyHours: &weeklyHours
                )
            }
            
            applyHolidayPayIfNeeded(
                to: &workPlaceBreakdown,
                workPlace: workPlace,
                weeklyHours: weeklyHours
            )
            PayAmountCalculator.applyFinalPay(to: &workPlaceBreakdown, taxType: workPlace.taxType)
            grandTotal.add(workPlaceBreakdown)
        }
        
        return grandTotal
    }

    // 비고정 근무지에서 아직 날짜가 정해지지 않은 남은 횟수만 평균값으로 예측합니다.
    private static func addFlexibleForecastPay(
        workPlace: WorkPlace,
        resolvedShifts: [ResolvedShift],
        targetMonth: Date,
        calendar: Calendar,
        breakdown: inout SalaryBreakdown,
        weeklyHours: inout WeeklyHolidayAllowanceCalculator.Bucket
    ) {
        guard let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: targetMonth) else {
            return
        }
        
        let targetCount = workPlace.targetWeeklyCount ?? 0
        let avgHours = workPlace.expectedDailyHours ?? 0.0
        
        for week in weekRange {
            let shiftsInThisWeek = resolvedShifts.filter {
                calendar.component(.weekOfMonth, from: $0.date) == week
            }
            
            let remainingCount = max(0, targetCount - shiftsInThisWeek.count)
            guard remainingCount > 0 else { continue }
            
            let predictedBasicPay = Int(Double(remainingCount) * avgHours * Double(workPlace.hourlyWage))
            let predictedHours = Double(remainingCount) * avgHours
            breakdown.basicPay += predictedBasicPay
            breakdown.monthlyWorkHours += predictedHours
            breakdown.workingDays += remainingCount
            
            let weekDate = shiftsInThisWeek.first?.date
                ?? representativeDate(forWeekOfMonth: week, in: targetMonth, calendar: calendar)
            WeeklyHolidayAllowanceCalculator.addHours(
                predictedHours,
                on: weekDate,
                calendar: calendar,
                to: &weeklyHours
            )
        }
    }

    // 저장 방식과 관계없이 Resolver가 선택한 날짜별 근무를 동일하게 계산합니다.
    private static func addResolvedShiftPay(
        shift: ResolvedShift,
        hourlyWage: Int,
        includeNightAllowance: Bool,
        calendar: Calendar,
        breakdown: inout SalaryBreakdown,
        weeklyHours: inout WeeklyHolidayAllowanceCalculator.Bucket
    ) {
        let worked = WorkTimeCalculator.calculate(
            start: shift.startTime,
            end: shift.endTime,
            restTime: shift.breakTime
        )
        addWorkedHoursPay(
            hours: worked,
            hourlyWage: hourlyWage,
            includeNightAllowance: includeNightAllowance,
            payDate: shift.date,
            calendar: calendar,
            breakdown: &breakdown,
            weeklyHours: &weeklyHours
        )
    }
    
    // 이미 계산된 근무시간을 SalaryBreakdown에 더하고, 주휴수당 계산용 주간 근무시간에도 누적합니다.
    private static func addWorkedHoursPay(
        hours: (total: Double, night: Double),
        hourlyWage: Int,
        includeNightAllowance: Bool,
        payDate: Date,
        calendar: Calendar,
        breakdown: inout SalaryBreakdown,
        weeklyHours: inout WeeklyHolidayAllowanceCalculator.Bucket
    ) {
        breakdown.add(
            PayAmountCalculator.payFromHours(
                hours: hours,
                hourlyWage: hourlyWage,
                includeNightAllowance: includeNightAllowance
            )
        )
        WeeklyHolidayAllowanceCalculator.addHours(
            hours.total,
            on: payDate,
            calendar: calendar,
            to: &weeklyHours
        )
    }
    
    // 근무지 설정에 주휴수당이 포함되어 있으면 주휴수당을 게산해서 반영합니다.
    private static func applyHolidayPayIfNeeded(
        to breakdown: inout SalaryBreakdown,
        workPlace: WorkPlace,
        weeklyHours: WeeklyHolidayAllowanceCalculator.Bucket
    ) {
        if workPlace.allowanceType.includesHoliday {
            breakdown.holidayPay = WeeklyHolidayAllowanceCalculator.holidayPay(
                from: weeklyHours,
                hourlyWage: workPlace.hourlyWage
            )
        } else {
            breakdown.holidayPay = 0
        }
    }
    
    // 자율 근무 예측 급여를 주휴수당 계산에 넣기 위해, 특정 주차를 대표하는 날짜를 찾습니다.
    private static func representativeDate(
        forWeekOfMonth weekOfMonth: Int,
        in month: Date,
        calendar: Calendar
    ) -> Date {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return month
        }
        
        var day = monthInterval.start
        while day < monthInterval.end {
            if calendar.component(.weekOfMonth, from: day) == weekOfMonth {
                return day
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = nextDay
        }
        return month
    }
    
}
