//
//  TaxType.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

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
