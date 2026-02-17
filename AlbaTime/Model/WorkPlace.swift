//
//  Workplace.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData

// MARK: - Enums
enum TaxType: String, Codable, CaseIterable {
    case none = "세금 없음"
    case threePointThree = "3.3% (사업소득세)"
    case fourMajor = "4대보험 (약 9.32%)"
    
    var rate: Double {
        switch self {
        case .none: return 0.0
        case .threePointThree: return 0.033
        case .fourMajor: return 0.0932
        }
    }
}

enum AllowanceType: String, Codable, CaseIterable {
    case none = "수당 없음"
    case holiday = "주휴수당"
    case night = "야간수당"
    case both = "주휴 + 야간"

    var includesHoliday: Bool {
        self == .holiday || self == .both
    }

    var includesNight: Bool {
        self == .night || self == .both
    }
}

enum WorkType: String, Codable, CaseIterable, Identifiable {
    case fixed = "요일 고정"
    case flexible = "횟수/시간 중심"
    var id: Self { self }
}

// MARK: - Workplace Model
@Model
class Workplace {
    var id: UUID
    var name: String
    var hourlyWage: Int
    var createdAt: Date
    
    // 고정 근무용 설정
    var defaultDays: String      // "월,수,금"
    var defaultStartTime: Date
    var defaultEndTime: Date
    
    var defaultMemo: String?
    var defaultRestTime: Int?
    
    var isPinned: Bool = false
    var isAlarmEnabled: Bool = true
    
    // Enum 저장
    var taxTypeRaw: String = TaxType.none.rawValue
    var allowanceTypeRaw: String = AllowanceType.none.rawValue
    var workTypeRaw: String = WorkType.fixed.rawValue
    
    // 자율 근무용 설정
    var targetWeeklyCount: Int?
    var expectedDailyHours: Double?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkSchedule.workplace)
    var workSchedules: [WorkSchedule] = []
    
    @Relationship(deleteRule: .cascade, inverse: \WorkTimePreset.workplace)
    var timePresets: [WorkTimePreset] = []
    
    @Relationship(deleteRule: .cascade, inverse: \RegularSchedule.workplace)
    var regularSchedules: [RegularSchedule] = []
    
    init(
        name: String,
        hourlyWage: Int,
        defaultDays: String,
        defaultStartTime: Date,
        defaultEndTime: Date,
        defaultRestTime: Int? = nil,
        defaultMemo: String? = nil,
        isAlarmEnabled: Bool = true,
        taxType: TaxType = .none,
        allowanceType: AllowanceType = .none,
        workType: WorkType = .fixed,
        targetWeeklyCount: Int? = nil,
        expectedDailyHours: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.hourlyWage = hourlyWage
        self.createdAt = Date()
        self.defaultDays = defaultDays
        self.defaultStartTime = defaultStartTime
        self.defaultEndTime = defaultEndTime
        self.defaultRestTime = defaultRestTime
        self.defaultMemo = defaultMemo ?? ""
        self.isAlarmEnabled = isAlarmEnabled
        self.taxTypeRaw = taxType.rawValue
        self.allowanceTypeRaw = allowanceType.rawValue
        self.workTypeRaw = workType.rawValue
        self.targetWeeklyCount = targetWeeklyCount
        self.expectedDailyHours = expectedDailyHours
    }
    
    var taxType: TaxType {
        get { TaxType(rawValue: taxTypeRaw) ?? .none }
        set { taxTypeRaw = newValue.rawValue }
    }
    
    var workType: WorkType {
        get { WorkType(rawValue: workTypeRaw) ?? .fixed }
        set { workTypeRaw = newValue.rawValue }
    }

    var allowanceType: AllowanceType {
        get { AllowanceType(rawValue: allowanceTypeRaw) ?? .none }
        set { allowanceTypeRaw = newValue.rawValue }
    }
}

// MARK: - Logic Extension (충돌 해결의 핵심)
extension Workplace {
    
    /// [핵심 로직] 특정 날짜에 근무가 있는지 판단
    /// - 1순위: AI/수기로 저장된 기록 (무조건 최우선)
    /// - 2순위: 고정 근무 패턴 (자율 근무제는 해당 없음)
    func getSchedule(for date: Date) -> (startTime: Date, endTime: Date, title: String?)? {
        let calendar = Calendar.current
        
        // 1. 개별 기록(AI/수기) 확인 -> 자율/고정 모두 최우선 적용
        if let actualRecord = workSchedules.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return (actualRecord.startTime, actualRecord.endTime, actualRecord.memo)
        }
        
        // 2. 고정 근무 패턴 확인 (자율 근무는 여기서 탈락)
        if workType == .fixed {
            let weekdayStr = date.koreanWeekday
            
            // A. 상세 요일 설정
            if let regular = regularSchedules.first(where: { $0.dayOfWeek == weekdayStr }) {
                let start = combineDateAndTime(date: date, time: regular.startTime)
                var end = combineDateAndTime(date: date, time: regular.endTime)
                if end < start { end = calendar.date(byAdding: .day, value: 1, to: end) ?? end }
                return (start, end, nil)
            }
            
            // B. 간편 요일 설정
            else if regularSchedules.isEmpty && defaultDays.contains(weekdayStr) {
                let start = combineDateAndTime(date: date, time: defaultStartTime)
                var end = combineDateAndTime(date: date, time: defaultEndTime)
                if end < start { end = calendar.date(byAdding: .day, value: 1, to: end) ?? end }
                return (start, end, nil)
            }
        }
        
        return nil
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
    }
}
