//
//  SaveWorkPlaceError.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

enum SaveWorkPlaceError: LocalizedError {
    case emptyName
    case invalidWage
    case missingFixedSchedule
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "매장명을 입력해주세요."
        case .invalidWage:
            return "올바른 시급을 입력해주세요."
        case .missingFixedSchedule:
            return "요일별 근무 시간 입력 또는 AI 스케줄을 인식해주세요."
        case .saveFailed(let message):
            return "저장 중 오류가 발생했어요. \(message)"
        }
    }
}
