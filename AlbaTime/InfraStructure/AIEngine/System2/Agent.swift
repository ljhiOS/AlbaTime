//
//  Agent.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import FoundationModels
import Foundation
import UIKit

@available(iOS 26.0, *)
@Generable
struct AIScheduleExtraction {
    var schedules: [AISchedule]
}

@available(iOS 26.0, *)
@Generable
struct AISchedule {
    var date: String
    var startTime: String
    var endTime: String
    var workLabel: String?
}

@available(iOS 26.0, *)
struct AgentModel: ImageAnalyzing {
    
    private let session = LanguageModelSession()
    
    func analyze(name: String?, year: Int, image: UIImage) async throws -> AIScheduleExtraction {
        let targetInstructions: String
        
        if let name {
            targetInstructions = """
                이 이미지는 \(name)의 근무 스케줄표입니다.
                
                이미지에 실제로 표시된 \(name)의 근무 일정만 추출하세요.
                다른 사람의 근무 일정은 포함하지 마세요.
                """
        } else {
            targetInstructions = """
                이 이미지는 근무 스케줄 표입니다.
                
                이미지에 실제로 표시된 모든 사람의 근무 일정을 추출하세요.
                특정 사람의 일정만 선택하지 말고, 식별 가능한 모든 근무 일정을 포함하세요.
                """
        }
        
        let prompt =
                """
                \(targetInstructions)
                
                각 일정에 대해 다음 정보를 반환하세요.
                
                - date
                
                  - yyyy-MM-dd 형식
                
                  - 연도가 이미지에 없으면 주어진 기준 연도를 사용
                
                  - 날짜를 식별할 수 없으면 nil
                
                - startTime
                
                  - HH:mm 형식
                
                  - 출근 시간이 없는 경우 nil
                
                - endTime
                
                  - HH:mm 형식
                
                  - 퇴근 시간이 없는 경우 nil
                
                - workLabel
                
                  - 근무지 또는 근무 유형이 명시된 경우에만 반환
                
                  - 없으면 nil
                """
        
        let response = try await session.respond(
            generating: AIScheduleExtraction.self
        ) {
            prompt
            
//            Attachment(image)
        }
        
        return response.content
    }
}
