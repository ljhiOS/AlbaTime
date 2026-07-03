//
//  WorkSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation
import SwiftData

// 자율로 저장하거나 ai로 저장한 근무 데이터들이 들어가는 모델
@Model
class WorkSchedule {
    var id: UUID
    var date: Date          // 근무 날짜
    var startTime: Date     // 시작 시간
    var endTime: Date       // 종료 시간
    var breakTime: Int      // 휴게 시간 (분)
    var memo: String?       // "오픈", "미들" 라벨 저장
    var isFromAIImport: Bool = false
    var aiImportBatchID: String?
    var isEditedAfterAIImport: Bool = false
    
    // WorkPlace와의 관계 (Inverse)
    @Relationship(originalName: "workplace")
    var workPlace: WorkPlace?
    
    init(
        date: Date,
        startTime: Date,
        endTime: Date,
        breakTime: Int = 0,
        memo: String? = nil,
        isFromAIImport: Bool = false,
        aiImportBatchID: String? = nil,
        isEditedAfterAIImport: Bool = false,
        workPlace: WorkPlace? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
        self.memo = memo
        self.isFromAIImport = isFromAIImport
        self.aiImportBatchID = aiImportBatchID
        self.isEditedAfterAIImport = isEditedAfterAIImport
        self.workPlace = workPlace
    }
}
