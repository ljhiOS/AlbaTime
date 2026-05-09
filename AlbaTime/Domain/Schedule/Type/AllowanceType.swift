//
//  AllowanceType.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

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
