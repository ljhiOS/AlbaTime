//
//  PayViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import Foundation
import Combine

@MainActor
class PayViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var currentMonth: Date = Date()
    @Published var actualReceivedAmount: String = "" // 실제 수령액 (유저 입력)
    
    // MARK: - Output
    @Published var salaryData: SalaryBreakdown = .empty
    @Published var projectedSalaryData: SalaryBreakdown = .empty
    @Published var averageWage: Int = 0
    
    // MARK: - Logic
    func updateData(workplaces: [Workplace]) {
        let accrued = SalaryCalculator.calculateAccruedMonthlyPay(
            workplaces: workplaces,
            targetMonth: currentMonth,
            asOf: Date()
        )
        
        let projected = SalaryCalculator.calculateTotalMonthlyPay(
            workplaces: workplaces,
            targetMonth: currentMonth
        )
        
        self.salaryData = accrued
        self.projectedSalaryData = projected
        self.averageWage = SalaryCalculator.calculateAverageWage(
            basicPay: accrued.basicPay,
            totalHours: accrued.totalHours
        )
    }
}
