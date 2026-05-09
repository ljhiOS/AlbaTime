//
//  AnalyzeScheduleImageUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import UIKit

struct AnalyzeScheduleImage {
    func execute(
        image: UIImage,
        targetName: String,
        presets: [WorkTimePreset]
    ) async throws -> [ParsedSchedule] {
        let rawBoxes = try await OCRService.shared.recognize(from: image)
        let textRows = TextLayoutAnalyzer.groupByRow(rawBoxes)

        return ScheduleParser.shared.parse(
            rows: textRows,
            presets: presets,
            targetName: targetName
        )
    }
}

