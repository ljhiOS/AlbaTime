//
//  Job.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//



import Foundation
import SwiftData

@Model
class Workplace {
    var id: UUID
    var name: String        // 가게 이름 (예: GS25 강남점)
    var hourlyWage: Int     // 시급 (예: 9860)
    var createdAt: Date     // 생성일
    
    var defaultDays: String      // 근무 요일 (예: "월,수,금")
    var defaultStartTime: Date // 시작 시간 (예: "09:00")
    var defaultEndTime: Date  // 종료 시간 (예: "18:00")
//    v/*ar allTimes: String        // 총 근무 시간*/
    var defaultMemo: String?
    var defaultRestTime: Int?
    
    var isPinned: Bool = false // 상단 고정용 변수
    
    var isAlarmEnabled: Bool = true // 알람 설정용 변수
    
    var taxType: TaxType = TaxType.none
    
    init(name: String, hourlyWage: Int, defaultDays: String, defaultStartTime: Date, defaultEndTime: Date /*, allTimes: String*/, defaultRestTime: Int? = nil, defaultMemo: String? = nil, isAlarmEnabled: Bool = true, taxType: TaxType = .none) {
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
        self.taxType = taxType
//        self.allTimes = allTimes
    }
}

// 정한 날짜 수정을 위한 익스텐션.. ux 고려하기 이렇게 힘들다니
extension Workplace {
    private var dayOrder: [String: Int] {
        ["일": 7, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
    }
    
    func isDaySelected(_ day: String) -> Bool {
        return self.defaultDays.components(separatedBy: "/").contains(day)
    }
    
    func toggleDay(_ day: String) {
        var currentDays = self.defaultDays.components(separatedBy: "/").filter { !$0.isEmpty }
        
        if currentDays.contains(day) {
            currentDays.removeAll { $0 == day }
        } else {
            currentDays.append(day)
        }
        
        currentDays.sort {
            (dayOrder[$0] ?? 99) < (dayOrder[$1] ?? 99)
        }
        
        if currentDays.isEmpty {
            self.defaultDays = ""
        } else {
            self.defaultDays = currentDays.joined(separator: "/")
        }
    }
}

enum TaxType: String, Codable, CaseIterable {
    case none = "세금 없음"
    case threePointThree = "3.3% (사업소득세)"
    case fourMajor = "4대보험 (약 9.32%)"
    
    // 세율 계산용 프로퍼티
    var rate: Double {
        switch self {
        case .none: return 0.0
        case .threePointThree: return 0.033
        case .fourMajor: return 0.0932 // 2024년 기준 근로자 부담분 대략적 합계 (국민+건강+요양+고용)
        }
    }
}
