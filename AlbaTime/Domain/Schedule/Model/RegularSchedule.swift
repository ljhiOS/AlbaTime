//
//  RegularSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData

// 고정 근무 요일/시간 설정 모델
@Model
class RegularSchedule {
    var id: UUID
    var dayOfWeek: String // "월", "화"
    var startTime: Date
    var endTime: Date
    var breakTime: Int // 휴게시간
    
    @Relationship(originalName: "workplace")
    var workPlace: WorkPlace?
    
    // 휴게시간을 함께 저장한다.
    init(dayOfWeek: String, startTime: Date, endTime: Date, breakTime: Int = 60) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
    }
}
