//
//  Agent.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import FoundationModels
import Foundation
import UIKit

@available(iOS 27.0, *)
@Generable
struct AIScheduleExtraction {
    @Guide(description: "선택한 주에 실제 근무가 확인된 일정만 포함")
    var schedules: [AISchedule]
}

@available(iOS 27.0, *)
@Generable
struct AISchedule {
    @Guide(description: "근무 날짜, yyyy-MM-dd 형식")
    var date: String

    @Guide(description: "이미지에 표시된 출근 시간, HH:mm 형식. 프리셋 라벨만 보이면 nil")
    var startTime: String?

    @Guide(description: "이미지에 표시된 퇴근 시간, HH:mm 형식. 프리셋 라벨만 보이면 nil")
    var endTime: String?

    @Guide(description: "이미지에 표시된 오픈·마감 등 근무 유형 라벨. 없으면 nil")
    var workLabel: String?
}

@MainActor
@available(iOS 27.0, *)
struct AgentModel: ImageAnalyzing {
    func analyze(
        name: String?,
        referenceDate: Date,
        presets: [AgentSchedulePreset],
        image: UIImage
    ) async throws -> AIScheduleExtraction {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: referenceDate)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let presetDescriptions = presets.isEmpty
            ? "등록된 프리셋 없음"
            : presets.map { "\($0.label): \($0.startTime)~\($0.endTime)" }.joined(separator: "\n")
        let targetInstructions: String

        if let name, !name.isEmpty {
            targetInstructions = """
                대상 이름은 "\(name)"입니다. 이 사람의 행이나 칸에 속한 일정만 추출하세요.
                다른 사람의 일정이나 소속이 불분명한 일정은 제외하세요.
                """
        } else {
            targetInstructions = """
                대상 이름이 지정되지 않았습니다. 이미지에서 소속과 날짜가 확인되는 모든 근무 일정을 추출하세요.
                """
        }
        let prompt = """
            이 이미지는 근무표입니다. 선택한 주는 \(weekStart.format("yyyy-MM-dd"))부터 \(weekEnd.format("yyyy-MM-dd"))까지입니다.
            \(targetInstructions)

            선택한 주에 속하고 이미지에서 실제 근무가 확인되는 일정만 반환하세요.
            날짜에 연도가 없으면 선택한 주의 해당 월/일에 맞는 연도를 사용하고, 요일만 있으면 선택한 주의 해당 요일에 연결하세요.
            이미지에 다른 주의 날짜가 명시돼 있으면 선택한 주로 옮기지 말고 제외하세요.
            휴무, 빈칸, 제목, 추측한 일정은 반환하지 마세요. 날짜를 확인할 수 없거나 입력된 대상 이름과의 대응이 불분명하면 그 일정은 제외하세요.

            등록된 근무 시간 프리셋:
            \(presetDescriptions)

            각 일정의 date는 yyyy-MM-dd 형식으로 반환하세요.
            출근·퇴근 시간이 표시돼 있으면 startTime과 endTime을 24시간제 HH:mm 형식으로 반환하세요.
            자정을 넘는 근무는 이미지의 시작·종료 시각 그대로 반환하세요. 종료가 자정이면 24:00도 사용할 수 있습니다.
            시간 대신 등록된 프리셋 라벨만 보이면 두 시간은 nil로, workLabel은 그 라벨로 반환하세요.
            시간이 하나만 보이거나 등록되지 않은 라벨만 보이면 시간을 추측하지 말고 그 일정은 제외하세요.
            workLabel에는 이미지에 표시된 근무 유형만 넣고, 사람 이름이나 근무지 이름은 넣지 마세요.
            같은 근무를 중복해서 반환하지 마세요.
            """

        try Task.checkCancellation()
        let session = LanguageModelSession()
        let response = try await session.respond(
            generating: AIScheduleExtraction.self
        ) {
            prompt

            Attachment(image)
        }

        try Task.checkCancellation()
        return response.content
    }
}
