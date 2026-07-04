//
//  SalaryCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation

struct SalaryCalculator {
    private struct WeekKey: Hashable {
        let yearForWeekOfYear: Int
        let weekOfYear: Int
    }
    
    // MARK: - Daily Pay
    static func calculateDailyPay(
        schedule: WorkSchedule,
        hourlyWage: Int,
        includeNightAllowance: Bool = true
    ) -> Int {
        let hours = calculateWorkingHours(start: schedule.startTime, end: schedule.endTime, restTime: schedule.breakTime)
        let payData = calculatePayFromHours(
            hours: hours,
            hourlyWage: hourlyWage,
            includeNightAllowance: includeNightAllowance
        )
        return payData.totalPay
    }

    // TODO: 시간 계산과 급여계산 로직 분기 검토
    // MARK: - Accrued Monthly Pay
    // 이번 달 1일부터 기준일(asOf)까지의 스케줄만 반영한다.
    static func calculateAccruedMonthlyPay(
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
            var weeklyHours: [WeekKey: Double] = [:]

            var day = startOfMonth
            while day <= cutoffDay {
                if let schedule = workPlace.getSchedule(for: day) {
                    let start = schedule.startTime
                    var end = schedule.endTime
                    if end < start {
                        end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
                    }

                    // 해당 근무의 종료 시각이 기준 시각(asOf) 이전일 때만 누적 반영
                    guard end <= cutoffDate else {
                        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                            break
                        }
                        day = nextDay
                        continue
                    }

                    let restMinutes = resolvedRestMinutes(workPlace: workPlace, day: day)
                    let worked = calculateWorkingHours(start: start, end: end, restTime: restMinutes)
                    workPlaceBreakdown.add(
                        calculatePayFromHours(
                            hours: worked,
                            hourlyWage: workPlace.hourlyWage,
                            includeNightAllowance: workPlace.allowanceType.includesNight
                        )
                    )
                    addWeeklyHours(worked.total, on: day, calendar: calendar, bucket: &weeklyHours)
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                    break
                }
                day = nextDay
            }

            if workPlace.allowanceType.includesHoliday {
                workPlaceBreakdown.holidayPay = holidayPayFromWeeklyHours(weeklyHours, hourlyWage: workPlace.hourlyWage)
            } else {
                workPlaceBreakdown.holidayPay = 0
            }
            let gross = workPlaceBreakdown.basicPay + workPlaceBreakdown.nightPay + workPlaceBreakdown.holidayPay
            let tax = Int(Double(gross) * workPlace.taxType.rate)
            workPlaceBreakdown.taxAmount = tax
            workPlaceBreakdown.totalPay = gross - tax

            grandTotal.add(workPlaceBreakdown)
        }

        return grandTotal
    }
    
    // MARK: - Monthly Pay
    // 실제 기록을 우선 반영하고, 부족한 구간만 예측치로 보완한다.
    static func calculateTotalMonthlyPay(workPlaces: [WorkPlace], targetMonth: Date) -> SalaryBreakdown {
        var grandTotal = SalaryBreakdown.empty
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: targetMonth) else { return .empty }
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        for workPlace in workPlaces {
            var workPlaceBreakdown = SalaryBreakdown.empty
            var weeklyHours: [WeekKey: Double] = [:]
            
            // 이번 달 실제 근무 기록
            let actualSchedules = workPlace.workSchedules.filter {
                calendar.isDate($0.date, equalTo: targetMonth, toGranularity: .month)
            }
            
            // 고정 근무: 월 전체 일자 순회
            if workPlace.workType == .fixed {
                // 실제 기록이 있는 날짜(예측 중복 방지)
                let recordedDates = Set(actualSchedules.map { calendar.startOfDay(for: $0.date) })
                
                // 실제 기록 반영
                for schedule in actualSchedules {
                    let worked = calculateWorkingHours(
                        start: schedule.startTime,
                        end: schedule.endTime,
                        restTime: schedule.breakTime
                    )
                    workPlaceBreakdown.add(
                        calculatePayFromHours(
                            hours: worked,
                            hourlyWage: workPlace.hourlyWage,
                            includeNightAllowance: workPlace.allowanceType.includesNight
                        )
                    )
                    addWeeklyHours(worked.total, on: schedule.date, calendar: calendar, bucket: &weeklyHours)
                }
                
                // 기록이 없는 날만 고정 패턴으로 예측
                var currentDate = startOfMonth
                while currentDate < endOfMonth {
                    if !recordedDates.contains(calendar.startOfDay(for: currentDate)) {
                        let weekday = currentDate.koreanWeekday
                        
                        if workPlace.hasAIOverrideInWeek(containing: currentDate) {
                            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                                break
                            }
                            currentDate = nextDate
                            continue
                        }
                        
                        
                        // 요일별 상세 설정
                        if let regular = workPlace.regularSchedules.first(where: { $0.dayOfWeek == weekday }) {
                            let hours = calculateWorkingHours(
                                start: regular.startTime,
                                end: regular.endTime,
                                restTime: workPlace.defaultRestTime ?? 0
                            )
                            workPlaceBreakdown.add(
                                calculatePayFromHours(
                                    hours: hours,
                                    hourlyWage: workPlace.hourlyWage,
                                    includeNightAllowance: workPlace.allowanceType.includesNight
                                )
                            )
                            addWeeklyHours(hours.total, on: currentDate, calendar: calendar, bucket: &weeklyHours)
                        }
                        // 간편 요일 설정
                        else if workPlace.regularSchedules.isEmpty && workPlace.defaultDays.contains(weekday) {
                            let hours = calculateWorkingHours(
                                start: workPlace.defaultStartTime,
                                end: workPlace.defaultEndTime,
                                restTime: workPlace.defaultRestTime ?? 0
                            )
                            workPlaceBreakdown.add(
                                calculatePayFromHours(
                                    hours: hours,
                                    hourlyWage: workPlace.hourlyWage,
                                    includeNightAllowance: workPlace.allowanceType.includesNight
                                )
                            )
                            addWeeklyHours(hours.total, on: currentDate, calendar: calendar, bucket: &weeklyHours)
                        }
                    }

                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = nextDate
                }
            }
            
            // 자율 근무: 주 단위로 실제+예측 혼합 계산
            else {
                if let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: targetMonth) {
                    let targetCount = workPlace.targetWeeklyCount ?? 0
                    let avgHours = workPlace.expectedDailyHours ?? 0.0
                    
                    for week in weekRange {
                        // 해당 주의 실제 기록
                        let schedulesInThisWeek = actualSchedules.filter {
                            calendar.component(.weekOfMonth, from: $0.date) == week
                        }
                        
                        // 실제 기록은 목표 횟수와 무관하게 전부 반영
                        for schedule in schedulesInThisWeek {
                            let worked = calculateWorkingHours(
                                start: schedule.startTime,
                                end: schedule.endTime,
                                restTime: schedule.breakTime
                            )
                            workPlaceBreakdown.add(
                                calculatePayFromHours(
                                    hours: worked,
                                    hourlyWage: workPlace.hourlyWage,
                                    includeNightAllowance: workPlace.allowanceType.includesNight
                                )
                            )
                            addWeeklyHours(worked.total, on: schedule.date, calendar: calendar, bucket: &weeklyHours)
                        }
                        
                        // 목표 대비 부족 횟수 계산
                        let workedCount = schedulesInThisWeek.count
                        let remainingCount = max(0, targetCount - workedCount)
                        
                        // 부족분만 예측치 반영
                        if remainingCount > 0 {
                            let predictedBasicPay = Int(Double(remainingCount) * avgHours * Double(workPlace.hourlyWage))
                            let predictedHours = Double(remainingCount) * avgHours
                            
                            workPlaceBreakdown.basicPay += predictedBasicPay
                            workPlaceBreakdown.monthlyWorkHours += predictedHours
                            workPlaceBreakdown.workingDays += remainingCount

                            let weekDate = schedulesInThisWeek.first?.date
                                ?? representativeDate(forWeekOfMonth: week, in: targetMonth, calendar: calendar)
                            addWeeklyHours(predictedHours, on: weekDate, calendar: calendar, bucket: &weeklyHours)
                        }
                    }
                }
            }
            
            // 주휴수당, 세금, 실수령액 계산
            if workPlace.allowanceType.includesHoliday {
                workPlaceBreakdown.holidayPay = holidayPayFromWeeklyHours(weeklyHours, hourlyWage: workPlace.hourlyWage)
            } else {
                workPlaceBreakdown.holidayPay = 0
            }
            let gross = workPlaceBreakdown.basicPay + workPlaceBreakdown.nightPay + workPlaceBreakdown.holidayPay
            let tax = Int(Double(gross) * workPlace.taxType.rate)
            workPlaceBreakdown.taxAmount = tax
            workPlaceBreakdown.totalPay = gross - tax
            
            grandTotal.add(workPlaceBreakdown)
        }
        
        return grandTotal
    }
    
    // MARK: - Helpers
    
    static func calculateAverageWage(basicPay: Int, totalHours: Double) -> Int {
        guard totalHours > 0 else { return 0 }
        return Int(Double(basicPay) / totalHours)
    }

    private static func weekKey(for date: Date, calendar: Calendar) -> WeekKey {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return WeekKey(
            yearForWeekOfYear: comps.yearForWeekOfYear ?? 0,
            weekOfYear: comps.weekOfYear ?? 0
        )
    }

    private static func addWeeklyHours(
        _ hours: Double,
        on date: Date,
        calendar: Calendar,
        bucket: inout [WeekKey: Double]
    ) {
        guard hours > 0 else { return }
        let key = weekKey(for: date, calendar: calendar)
        bucket[key, default: 0] += hours
    }

    private static func holidayPayFromWeeklyHours(
        _ weeklyHours: [WeekKey: Double],
        hourlyWage: Int
    ) -> Int {
        weeklyHours.values.reduce(0) { partial, hours in
            guard hours >= 15 else { return partial }
            let weeklyHolidayHours = (hours / 40.0) * 8.0
            return partial + Int(weeklyHolidayHours * Double(hourlyWage))
        }
    }

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

    private static func resolvedRestMinutes(workPlace: WorkPlace, day: Date) -> Int {
        let calendar = Calendar.current

        if let actual = workPlace.workSchedules.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            return max(0, actual.breakTime)
        }

        if let regular = workPlace.regularSchedules.first(where: { $0.dayOfWeek == day.koreanWeekday }) {
            return max(0, regular.breakTime)
        }

        return max(0, workPlace.defaultRestTime ?? 0)
    }
    
    // 야간/휴게시간을 포함한 근무시간 계산
    private static func calculateWorkingHours(start: Date, end: Date, restTime: Int) -> (total: Double, night: Double) {
        let calendar = Calendar.current
        let startH = calendar.component(.hour, from: start)
        let startM = calendar.component(.minute, from: start)
        let endH = calendar.component(.hour, from: end)
        let endM = calendar.component(.minute, from: end)
        
        let startMins = startH * 60 + startM
        var endMins = endH * 60 + endM
        // 자정을 넘기는 종료 시간 처리
        if endMins < startMins { endMins += 1440 }
        
        let rawDiffMins = Double(endMins - startMins)
        let netDiffMins = max(0, rawDiffMins - Double(restTime))
        let totalHours = netDiffMins / 60.0
        
        // 야간 근무(22:00 ~ 06:00)
        var nightMinsCount = 0
        for t in startMins..<endMins {
            let normalized = t % 1440
            if normalized < 360 || normalized >= 1320 { nightMinsCount += 1 }
        }
        
        // 총 근무 대비 비율로 야간시간 보정
        let ratio = rawDiffMins > 0 ? netDiffMins / rawDiffMins : 1.0
        let nightHours = (Double(nightMinsCount) * ratio) / 60.0
        
        return (totalHours, nightHours)
    }
    
    // 시간 정보를 급여 명세로 변환
    private static func calculatePayFromHours(
        hours: (total: Double, night: Double),
        hourlyWage: Int,
        includeNightAllowance: Bool
    ) -> SalaryBreakdown {
        let wage = Double(hourlyWage)
        let basic = Int(hours.total * wage)
        let night = includeNightAllowance ? Int(hours.night * wage * 0.5) : 0
        let total = basic + night
        
        return SalaryBreakdown(
            basicPay: basic,
            nightPay: night,
            holidayPay: 0,
            taxAmount: 0,
            totalPay: total,
            monthlyWorkHours: hours.total,
            accruedWorkHours: hours.total,
            workingDays: 1
        )
    }
}
