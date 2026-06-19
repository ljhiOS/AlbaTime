//
//  JobDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct JobDraft {
    var name: String
    var hourlyWage: Int

    var defaultRestTime: Int
    var defaultMemo: String

    var taxType: TaxType
    var allowanceType: AllowanceType
    var workType: WorkType

    var targetWeeklyCount: Int
    var expectedDailyHours: Double

    // 선택 날짜 데이터 배열
    var regularSchedules: [RegularScheduleDraft]

}

// 고정된 월~일 중 선택된 날짜 데이터
struct RegularScheduleDraft: Identifiable {
    let id: UUID
    var dayOfWeek: String
    var startTime: Date
    var endTime: Date
    var breakTime: Int
}

extension JobDraft {
    static func makeNew(type: WorkType) -> JobDraft {
        JobDraft(
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
