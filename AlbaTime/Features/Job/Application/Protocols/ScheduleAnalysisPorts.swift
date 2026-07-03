//
//  ScheduleAnalysisPorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

// AI 스케줄 분석 관련 port 기능을 정의

import Foundation

protocol ScheduleImageTextRecognizing: Sendable {
    func recognize(from imageData: Data) async throws -> [RawTextBox]
}

protocol ScheduleTextParsing: Sendable {
    func parse(
        rows: [TextRow],
        presets: [TimePresetDraft],
        targetName: String
    ) -> [ParsedSchedule]
}

