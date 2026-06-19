//
//  ScheduleDraftItem.swift
//  AlbaTime
//
//  Created by 이준희 on 5/3/26.
//

import Foundation

enum ScheduleDraftSource: Equatable {
    case aiImport
    case manual
}

// 저장 시 DB Operation으로 변환할지 알려주는 변경 추적 상태
enum ScheduleDraftChangeState: Equatable {
    case clean
    case inserted
    case updated
    case deleted
}

struct ScheduleDraftItem: Identifiable {
    let id: UUID
    var originalScheduleID: UUID? = nil
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakTime: Int
    var memo: String?
    var source: ScheduleDraftSource
    var changeState: ScheduleDraftChangeState = .inserted
}

extension ScheduleDraftItem {
    init(
        parsedSchedule: ParsedSchedule,
        breakTime: Int,
        source: ScheduleDraftSource
    ) {
        self.id = parsedSchedule.id
        self.date = parsedSchedule.date
        self.startTime = parsedSchedule.startTime
        self.endTime = parsedSchedule.endTime
        self.breakTime = breakTime
        self.memo = parsedSchedule.workLabel
        self.source = source
        self.originalScheduleID = nil
        self.changeState = .inserted
    }

}

typealias ScheduleEditItem = ScheduleDraftItem
typealias ScheduleEditSource = ScheduleDraftSource
