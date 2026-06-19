//
//  ParsedSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import Foundation

// OCR 결과 앱 데이터로 변환한 최종 결과물
// 날짜 중 하나 배열로 쓰임
struct ParsedSchedule: Identifiable {
    let id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var workLabel: String?

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        workLabel: String?
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.workLabel = workLabel
    }
}
