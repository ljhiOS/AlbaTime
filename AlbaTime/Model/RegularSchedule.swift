//
//  RegularSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData

// 존재 이유: 고정 근무 계획표
// 고정 근무와 자율 근무제 중 고정 근무를 표시하는 모델
@Model
class RegularSchedule {
    var id: UUID
    var dayOfWeek: String // "월", "화"
    var startTime: Date
    var endTime: Date
    var breakTime: Int // 휴게시간
    
    var workplace: Workplace?
    
    // 🔥 breakTime까지 포함된 init이 필요합니다.
    init(dayOfWeek: String, startTime: Date, endTime: Date, breakTime: Int = 60) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
    }
}
