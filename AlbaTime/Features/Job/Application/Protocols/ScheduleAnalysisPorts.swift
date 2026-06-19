//
//  ScheduleAnalysisPorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import UIKit

protocol ScheduleImageTextRecognizing: Sendable {
    func recognize(from image: UIImage) async throws -> [RawTextBox]
}

protocol ScheduleTextParsing: Sendable {
    func parse(
        rows: [TextRow],
        presets: [TimePresetDraft],
        targetName: String
    ) -> [ParsedSchedule]
}
