//
//  WorkTimePreset.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation
import SwiftData

// 존재 이유: ai 인식 스케줄표 중 시간으로 적힌 것이 아닌 오픈 미들 마감 등 글자로 온 스케줄표를 위해 선제적 저장 모델
@Model
class WorkTimePreset {
    var id: UUID
    var label: String       // "오픈", "미들", "마감" 등
    var startTime: Date
    var endTime: Date
    
    var workplace: Workplace? // 부모 가게
    
    init(label: String, startTime: Date, endTime: Date) {
        self.id = UUID()
        self.label = label
        self.startTime = startTime
        self.endTime = endTime
    }
}
