//
//  PayViewModel.swift
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
    @Published var salaryData: SalaryBreakdown = .empty
    @Published var averageWage: Int = 0
    
    // MARK: - Logic
    func updateData(workplaces: [Workplace]) {
        // [수정] 기존 calculateExpectedMonthlyPay 대신 하이브리드 로직 사용
        let breakdown = SalaryCalculator.calculateTotalMonthlyPay(
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
