//
//  AlbaTimeTests.swift
//  AlbaTimeTests
//
//  Created by 이준희 on 1/11/26.
//

import XCTest
@testable import AlbaTime // 내 앱 이름 (프로젝트명)

final class SalaryCalculatorTests: XCTestCase {

    // 테스트 1: 기본 급여 계산이 맞는지 확인
    func testBasicSalaryCalculation() {
        // 상황 설정 (Given)
        // 시급 10,000원, 9시~14시 (5시간) 근무, 휴게 없음
        let workplace = Workplace(
            name: "테스트 가게",
            hourlyWage: 10000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(14, 0),
            defaultRestTime: 0
        )
        
        // 실행 (When)
        let expectedPay = SalaryCalculator.calculateExpectedPay(workplace: workplace)
        
        // 검증 (Then)
        // 5시간 * 10,000원 = 50,000원이어야 함
        XCTAssertEqual(expectedPay, 50000, "기본 급여 계산이 틀렸습니다!")
    }

    // 테스트 2: 야간 수당이 잘 붙는지 확인
    func testNightAllowance() {
        // 상황 설정 (Given)
        // 시급 10,000원, 밤 22시 ~ 새벽 2시 (4시간) 근무
        // 야간 4시간 = (4 * 10,000) + (4 * 5,000) = 60,000원
        let workplace = Workplace(
            name: "야간 편의점",
            hourlyWage: 10000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(22, 0),
            defaultEndTime: Date.makeTime(2, 0), // 다음날 새벽 2시
            defaultRestTime: 0
        )
        
        // 실행 (When)
        let expectedPay = SalaryCalculator.calculateExpectedPay(workplace: workplace)
        
        // 검증 (Then)
        XCTAssertEqual(expectedPay, 60000, "야간 수당 계산이 틀렸습니다!")
    }
}
