//
//  WorkPlaceSaveValidator.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

// WorkPlace 저장 전 필요한 도메인 검증을 담당합니다.
struct WorkPlaceSaveValidator {
    // 근무지 이름의 유무와 올바른 시급을 판단합니다.
    func validate(draft: WorkPlaceDraft) throws {
        if draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SaveWorkPlaceError.emptyName
        }

        if draft.hourlyWage <= 0 {
            throw SaveWorkPlaceError.invalidWage
        }
    }
    
    // 고정된 근무지의 요일별 기본 스케줄 또는 초기 AI 스케줄 중 하나가 필요합니다.
    func validateFixedWorkPlace(
        orderedRegularSchedules: [RegularScheduleDraft],
        initialImportedSchedules: [ScheduleDraftItem]
    ) throws {
        if orderedRegularSchedules.isEmpty && initialImportedSchedules.isEmpty {
            throw SaveWorkPlaceError.missingFixedSchedule
        }
    }
}
