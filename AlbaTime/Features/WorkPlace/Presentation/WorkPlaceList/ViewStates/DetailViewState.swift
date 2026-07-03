//
//  DetailViewState.swift
//  AlbaTime
//
//  Created by 이준희 on 7/3/26.
//

import Foundation

struct WorkPlaceDetailViewState: Identifiable, Hashable {
    let id: UUID
    let name: String
    let hourlyWage: Int
    let workType: WorkType
    let fixedDaysText: String
    let defaultStartTime: Date
    let defaultEndTime: Date
    let targetWeeklyCount: Int
    let expectedDailyHours: Double
    let defaultRestTime: Int?
    var memo: String
    let totalDays: Int
    let totalHours: Double
    let totalWage: Int
}
