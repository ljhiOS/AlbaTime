//
//  SalaryBreakdown.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import Foundation

// MARK: - 급여 명세 데이터 구조체
struct SalaryBreakdown {
    var basicPay: Int       // 기본급
    var nightPay: Int       // 야간수당
    var holidayPay: Int     // 주휴수당
    var taxAmount: Int      // 세금
    var totalPay: Int       // 실수령액 (세후)
    var monthlyWorkHours: Double // 한달 총 근무시간
    var accruedWorkHours: Double // 누적 근무 시간
    var workingDays: Int    // 근무 일수
    
    // 빈 껍데기 생성용 (초기값)
    static var empty: SalaryBreakdown {
        return SalaryBreakdown(
            basicPay: 0,
            nightPay: 0,
            holidayPay: 0,
            taxAmount: 0,
            totalPay: 0,
            monthlyWorkHours: 0,
            accruedWorkHours: 0,
            workingDays: 0
        )
    }
    
    // 두 개의 급여 명세를 합치는 함수
    mutating func add(_ other: SalaryBreakdown) {
        self.basicPay += other.basicPay
        self.nightPay += other.nightPay
        self.holidayPay += other.holidayPay
        self.taxAmount += other.taxAmount
        self.totalPay += other.totalPay
        self.monthlyWorkHours += other.monthlyWorkHours
        self.accruedWorkHours += other.accruedWorkHours
        self.workingDays += other.workingDays
    }
}
