//
//  JobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import Foundation
import Combine

class PayViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var currentMonth: Date = Date()
    @Published var actualReceivedAmount: String = "" // 실제 수령액 (유저 입력)
    
    // MARK: - Output
    @Published var salaryData: SalaryBreakdown = SalaryBreakdown(
        basicPay: 0, nightPay: 0, overtimePay: 0, holidayPay: 0, taxAmount: 0, totalPay: 0, totalHours: 0, workingDays: 0
    )
    @Published var averageWage: Int = 0
    
    // MARK: - Logic
    func updateData(workplaces: [Workplace]) {
        // "기록" 상관없이 설정된 스케줄로만 계산
        let breakdown = SalaryCalculator.calculateExpectedMonthlyPay(
            workplaces: workplaces,
            targetMonth: currentMonth
        )
        
        self.salaryData = breakdown
        self.averageWage = SalaryCalculator.calculateAverageWage(
            basicPay: breakdown.basicPay,
            totalHours: breakdown.totalHours
        )
    }
}
