//
//  AgentScheduleImageAnalyzer.swift
//  AlbaTime
//
//  Created by Codex on 9/24/26.
//

import Foundation
import FoundationModels
import UIKit

@MainActor
@available(iOS 27.0, *)
struct AgentScheduleImageAnalyzer: ScheduleImageAnalyzing {
    private let agent: any ImageAnalyzing
    private let mapper = ScheduleMapper()

    init(agent: any ImageAnalyzing = AgentModel()) {
        self.agent = agent
    }

    func execute(
        imageData: Data,
        targetName: String,
        presets: [TimePresetDraft],
        referenceDate: Date
    ) async throws -> [ParsedSchedule] {
        guard SystemLanguageModel.default.isAvailable else {
            throw AgentScheduleImageError.modelUnavailable
        }
        guard let image = UIImage(data: imageData) else {
            throw ScheduleImageRecognitionError.invalidImageData
        }

        let agentPresets = presets.map {
            AgentSchedulePreset(
                label: $0.label.trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: $0.startTime.time24h,
                endTime: $0.endTime.time24h
            )
        }
        let name = targetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let extraction = try await agent.analyze(
            name: name.isEmpty ? nil : name,
            referenceDate: referenceDate,
            presets: agentPresets,
            image: image
        )
        try Task.checkCancellation()
        return mapper.mapping(
            aiSchedules: extraction,
            presets: agentPresets,
            referenceDate: referenceDate
        )
    }
}

private enum AgentScheduleImageError: LocalizedError {
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "기기에서 AI 분석 모델을 사용할 수 없어요. 수기로 일정을 입력해 주세요."
        }
    }
}
