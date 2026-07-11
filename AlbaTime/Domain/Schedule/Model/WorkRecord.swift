//
//  WorkRecord.swift
//  AlbaTime
//
//  Created by Codex on 7/11/26.
//

import Foundation
import SwiftData

// 예정 근무와 별도로 저장하는 날짜별 실제/조정 근무 기록
@Model
class WorkRecord {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakTime: Int

    @Relationship(originalName: "workplace")
    var workPlace: WorkPlace?

    init(
        date: Date,
        startTime: Date,
        endTime: Date,
        breakTime: Int,
        workPlace: WorkPlace? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
        self.workPlace = workPlace
    }
}
