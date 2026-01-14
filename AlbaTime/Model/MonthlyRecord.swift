//
//  MonthlyRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import Foundation
import SwiftData

@Model
final class MonthlyRecord {
    var id: UUID
    var year: Int
    var month: Int
    var actualAmount: String // 사용자가 입력한 금액 (계산 안 하니 String이 편함)
    
    init(year: Int, month: Int, actualAmount: String) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.actualAmount = actualAmount
    }
}
