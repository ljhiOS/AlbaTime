//
//  WorkPlace.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData

// 역할: 앱의 도메인 루트 엔티티
// 1) 근무지 자체 정보(이름, 시급, 세금/수당)
// 2) 근무 정책(고정/자율, 기본 요일/시간, 세금/수당)
// 3) 근무 기록 관계 집합(workSchedules, regularSchedules, timePresets)
// 4) 특정 날짜 근무 결정 로직(getSchedule(for:))

// MARK: - WorkPlace Model
@Model
class Workplace {
    var id: UUID
    var name: String
    var hourlyWage: Int
    var createdAt: Date
    
    // 기본 근무용 설정
    var defaultDays: String      // "월,수,금"
    var defaultStartTime: Date
    var defaultEndTime: Date
    
    var defaultMemo: String?
    var defaultRestTime: Int?
    
    // UI 상태
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
    @Relationship(deleteRule: .cascade, inverse: \WorkSchedule.workPlace)
    var workSchedules: [WorkSchedule] = []
    
    @Relationship(deleteRule: .cascade, inverse: \WorkTimePreset.workPlace)
    var timePresets: [WorkTimePreset] = []
    
    @Relationship(deleteRule: .cascade, inverse: \RegularSchedule.workPlace)
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

// 기존 SwiftData 저장소의 모델명이 Workplace로 배포되어 실제 @Model 클래스명은 유지합니다.
// 앱 코드에서는 typealias WorkPlace를 통해 WorkPlace 네이밍을 사용합니다.
typealias WorkPlace = Workplace

// MARK: extensions
extension Workplace {
    // 고정 근무지일 경우 해당 주 ai 스케줄로 변경시 그 데이터로 변경(캘린더 반영)
    func hasAIOverrideInWeek(containing date: Date) -> Bool {
        ScheduleResolver.hasAIOverride(in: self, containing: date)
    }
    
    /// [핵심 로직] 특정 날짜에 근무가 있는지 판단
    /// - 1순위: AI/수기로 저장된 기록 (무조건 최우선)
    /// - 2순위: 고정 근무 패턴 (자율 근무제는 해당 없음)
    func getSchedule(for date: Date) -> (startTime: Date, endTime: Date, title: String?)? {
        ScheduleResolver.resolve(workPlace: self, for: date)
    }
}
