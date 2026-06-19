//
//  ScheduleAnalysisAdapters.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation
import UIKit

struct OCRScheduleImageTextRecognizer: ScheduleImageTextRecognizing {
    private let service: OCRService

    init(service: OCRService = .shared) {
        self.service = service
    }

    func recognize(from image: UIImage) async throws -> [RawTextBox] {
        try await service.recognize(from: image)
    }
}

struct ScheduleParserJobAdapter: ScheduleTextParsing {
    private let parser: ScheduleParser

    init(parser: ScheduleParser = .shared) {
        self.parser = parser
    }

    func parse(
        rows: [TextRow],
        presets: [TimePresetDraft],
        targetName: String
    ) -> [ParsedSchedule] {
        parser.parse(
            rows: rows,
            presets: presets.map {
                WorkTimePreset(
                    label: $0.label,
                    startTime: $0.startTime,
                    endTime: $0.endTime
                )
            },
            targetName: targetName
        )
    }
}

enum DefaultScheduleAnalysis {
    static func makeUseCase() -> AnalyzeScheduleImage {
        AnalyzeScheduleImage(
            textRecognizer: OCRScheduleImageTextRecognizer(),
            textParser: ScheduleParserJobAdapter()
        )
    }
}
