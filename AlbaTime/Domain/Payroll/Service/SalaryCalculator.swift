//
//  SalaryCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation

struct SalaryCalculator {
    // 하루 근무 스케줄 기준으로 일급을 계산합니다.
    static func calculateDailyPay(
        schedule: WorkSchedule,
        hourlyWage: Int,
        includeNightAllowance: Bool = true
    ) -> Int {
        PayAmountCalculator.dailyPay(
            schedule: schedule,
            hourlyWage: hourlyWage,
            includeNightAllowance: includeNightAllowance
        )
    }
    
    // 월 누적 급여를 계산합니다.
    static func calculateAccruedMonthlyPay(
        workPlaces: [WorkPlace],
        targetMonth: Date,
        asOf: Date = Date()
    ) -> SalaryBreakdown {
        MonthlySalaryCalculator.accruedMonthlyPay(
            workPlaces: workPlaces,
            targetMonth: targetMonth,
            asOf: asOf
        )
    }
    
    // 월 총 예상 급여를 계산합니다.
    static func calculateTotalMonthlyPay(workPlaces: [WorkPlace], targetMonth: Date) -> SalaryBreakdown {
        MonthlySalaryCalculator.totalMonthlyPay(
            workPlaces: workPlaces,
            targetMonth: targetMonth
        )
    }
    
    // 평균 시급을 계산합니다.
    static func calculateAverageWage(basicPay: Int, totalHours: Double) -> Int {
        PayAmountCalculator.averageWage(basicPay: basicPay, totalHours: totalHours)
    }
}
