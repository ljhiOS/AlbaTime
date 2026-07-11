//
//  PayAmountCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import Foundation

struct PayAmountCalculator {
    // 하루 스케줄의 일급을 계산합니다.
    static func dailyPay(
        schedule: WorkSchedule,
        hourlyWage: Int,
        includeNightAllowance: Bool
    ) -> Int {
        let hours = WorkTimeCalculator.calculate(
            start: schedule.startTime,
            end: schedule.endTime,
            restTime: schedule.breakTime
        )
        return payFromHours(
            hours: hours,
            hourlyWage: hourlyWage,
            includeNightAllowance: includeNightAllowance
        ).totalPay
    }
    
    // 계산된 근무시간을 SalaryBreakdown으로 변환합니다.
    static func payFromHours(
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
    
    // 기본급 + 야간수당 + 주휴수당에서 세금을 계산하고 최종 실수령액을 반영합니다.
    static func applyFinalPay(to breakdown: inout SalaryBreakdown, taxType: TaxType) {
        let gross = breakdown.basicPay + breakdown.nightPay + breakdown.holidayPay
        let tax = Int(Double(gross) * taxType.rate)
        breakdown.taxAmount = tax
        breakdown.totalPay = gross - tax
    }
    
    // 기본급을 총 근무시간으로 나눠 평균 시급을 계산합니다.
    static func averageWage(basicPay: Int, totalHours: Double) -> Int {
        guard totalHours > 0 else { return 0 }
        return Int(Double(basicPay) / totalHours)
    }
}
