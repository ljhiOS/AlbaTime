//
//  CalendarWorkRecordSaving.swift
//  AlbaTime
//
//  Created by Codex on 7/11/26.
//

import Foundation

struct CalendarWorkRecordCommand {
    let workPlaceID: UUID
    let date: Date
    let startTime: Date
    let endTime: Date
    let breakTime: Int
}

@MainActor
protocol CalendarWorkRecordSaving {
    func execute(_ command: CalendarWorkRecordCommand) throws
}

@MainActor
protocol CalendarWorkRecordWriting {
    func saveWorkRecord(_ command: CalendarWorkRecordCommand) throws
}
