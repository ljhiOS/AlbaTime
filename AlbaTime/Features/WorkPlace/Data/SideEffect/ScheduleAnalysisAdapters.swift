//
//  ScheduleAnalysisAdapters.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation
import UIKit

enum ScheduleImageRecognitionError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "이미지 데이터를 불러올 수 없어요."
        }
    }
}

struct OCRScheduleImageTextRecognizer: ScheduleImageTextRecognizing {
    private let service: OCRService

    init(service: OCRService = .shared) {
        self.service = service
    }

    func recognize(from imageData: Data) async throws -> [RawTextBox] {
        guard let image = UIImage(data: imageData) else {
            throw ScheduleImageRecognitionError.invalidImageData
        }

        return try await service.recognize(from: image)
    }
}

struct ScheduleParserWorkPlaceAdapter: ScheduleTextParsing {
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
