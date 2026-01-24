//
//  WorkSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation
import SwiftData

// 존재이유: 개별 날짜의 저장을 위한 -> 자율 근무제의 핵심 모델
@Model
class WorkSchedule {
    var id: UUID
    var date: Date          // 근무 날짜
    var startTime: Date     // 시작 시간
    var endTime: Date       // 종료 시간
    var breakTime: Int      // 휴게 시간 (분)
    var memo: String?       // "오픈", "미들" 라벨 저장
    
    // Workplace와의 관계 (Inverse)
    var workplace: Workplace?
    
    init(date: Date, startTime: Date, endTime: Date, breakTime: Int = 0, memo: String? = nil, workplace: Workplace? = nil) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
        self.memo = memo
        self.workplace = workplace
    }
}
