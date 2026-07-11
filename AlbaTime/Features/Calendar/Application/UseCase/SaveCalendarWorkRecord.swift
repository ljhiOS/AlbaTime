//
//  SaveCalendarWorkRecord.swift
//  AlbaTime
//
//  Created by Codex on 7/11/26.
//

import Foundation

@MainActor
struct SaveCalendarWorkRecord: CalendarWorkRecordSaving {
    private let writer: any CalendarWorkRecordWriting

    init(writer: any CalendarWorkRecordWriting) {
        self.writer = writer
    }

    func execute(_ command: CalendarWorkRecordCommand) throws {
        try writer.saveWorkRecord(command)
    }
}
