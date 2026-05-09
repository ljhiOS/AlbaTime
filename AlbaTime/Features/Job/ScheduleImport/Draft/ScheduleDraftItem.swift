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
    case saved
}

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
    
    init(workSchedule: WorkSchedule) {
        self.id = workSchedule.id
        self.originalScheduleID = workSchedule.id
        self.date = workSchedule.date
        self.startTime = workSchedule.startTime
        self.endTime = workSchedule.endTime
        self.breakTime = workSchedule.breakTime
        self.memo = workSchedule.memo
        self.source = workSchedule.isFromAIImport ? .aiImport : .saved
        self.changeState = .clean
    }
    
    var parsedSchedule: ParsedSchedule {
        ParsedSchedule(
            id: id,
            date: date,
            startTime: startTime,
            endTime: endTime,
            workLabel: memo
        )
    }
}

typealias ScheduleEditItem = ScheduleDraftItem
typealias ScheduleEditSource = ScheduleDraftSource
typealias ScheduleEditChangeState = ScheduleDraftChangeState
