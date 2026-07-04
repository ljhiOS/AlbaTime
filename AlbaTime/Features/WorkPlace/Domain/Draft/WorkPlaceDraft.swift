//
//  WorkPlaceDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct WorkPlaceDraft {
    
    // 근무지명
    var name: String
    // 시급
    var hourlyWage: Int
    
    // 기본 휴식시간
    var defaultRestTime: Int
    // 기본 메모
    var defaultMemo: String

    // 세금 유형
    var taxType: TaxType
    // 수당 유형
    var allowanceType: AllowanceType
    // 자율 또는 고정 근무 유형
    var workType: WorkType

    // FIXME: 변수 명칭 변경 고려
    // 자율 근무 시 예상 주간 근무 횟수
    var targetWeeklyCount: Int
    // 자율 근무 시 예상 하루 평균 근무 시간
    var expectedDailyHours: Double

    // 선택 날짜 데이터 배열
    var regularSchedules: [RegularScheduleDraft]

}

// 고정된 월~일 중 선택된 날짜 데이터
struct RegularScheduleDraft: Identifiable {
    
    // 근무지 ID
    let id: UUID
    
    // 몇요일인지
    var dayOfWeek: String
    
    // 근무 시작시간
    var startTime: Date
    
    // 근무 종료시간
    var endTime: Date
    
    // 휴식시간
    var breakTime: Int
}

extension WorkPlaceDraft {
    static func makeNew(type: WorkType) -> WorkPlaceDraft {
        WorkPlaceDraft(
            name: "",
            hourlyWage: 0,
            defaultRestTime: 0,
            defaultMemo: "",
            taxType: .none,
            allowanceType: .none,
            workType: type,
            targetWeeklyCount: 3,
            expectedDailyHours: 5.0,
            regularSchedules: []
        )
    }
}
