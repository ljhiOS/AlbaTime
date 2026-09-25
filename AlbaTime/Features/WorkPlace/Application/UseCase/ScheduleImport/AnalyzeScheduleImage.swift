//
//  AnalyzeScheduleImageUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

struct AnalyzeScheduleImage: ScheduleImageAnalyzing, Sendable {
    private let textRecognizer: any ScheduleImageTextRecognizing
    private let textParser: any ScheduleTextParsing

    init(
        textRecognizer: any ScheduleImageTextRecognizing,
        textParser: any ScheduleTextParsing
    ) {
        self.textRecognizer = textRecognizer
        self.textParser = textParser
    }

    func execute(
        imageData: Data,
        targetName: String,
        presets: [TimePresetDraft],
        referenceDate: Date
    ) async throws -> [ParsedSchedule] {
        let name = targetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let customWords = ([name] + presets.map(\.label)).filter { !$0.isEmpty }
        let rawBoxes = try await textRecognizer.recognize(from: imageData, customWords: customWords)
        try Task.checkCancellation()
        let textRows = TextLayoutAnalyzer.groupByRow(rawBoxes)

        return textParser.parse(
            rows: textRows,
            presets: presets,
            targetName: name,
            referenceDate: referenceDate
        )
    }
}
