//
//  WeeklyHolidayAllowanceCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import Foundation

struct WeeklyHolidayAllowanceCalculator {
    struct Bucket {
        fileprivate var weeklyHours: [WeekKey: Double] = [:]
    }
    
    fileprivate struct WeekKey: Hashable {
        let yearForWeekOfYear: Int
        let weekOfYear: Int
    }
    
    // 주차별 근무시간을 누적할 빈 저장소를 만듭니다.
    static func makeBucket() -> Bucket {
        Bucket()
    }
    
    // 특정 날짜의 근무시간을 해당 주차에 누적합니다.
    static func addHours(
        _ hours: Double,
        on date: Date,
        calendar: Calendar,
        to bucket: inout Bucket
    ) {
        guard hours > 0 else { return }
        let key = weekKey(for: date, calendar: calendar)
        bucket.weeklyHours[key, default: 0] += hours
    }
    
    // 주차별 근무시간을 기준으로 주휴수당을 계산합니다.
    static func holidayPay(from bucket: Bucket, hourlyWage: Int) -> Int {
        bucket.weeklyHours.values.reduce(0) { partial, hours in
            guard hours >= 15 else { return partial }
            let weeklyHolidayHours = min((hours / 40.0) * 8.0, 8.0)
            return partial + Int(weeklyHolidayHours * Double(hourlyWage))
        }
    }
    
    // 날짜를 주차 Key로 변환합니다.
    private static func weekKey(for date: Date, calendar: Calendar) -> WeekKey {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return WeekKey(
            yearForWeekOfYear: comps.yearForWeekOfYear ?? 0,
            weekOfYear: comps.weekOfYear ?? 0
        )
    }
}
