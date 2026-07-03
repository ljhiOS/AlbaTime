//
//  ScheduleImageAnalyzing.swift
//  AlbaTime
//
//  Created by 이준희 on 7/3/26.
//

import Foundation

@MainActor
protocol ScheduleImageAnalyzing {
    func execute(
        imageData: Data,
        targetName: String,
        presets: [TimePresetDraft]
    ) async throws -> [ParsedSchedule]
}
