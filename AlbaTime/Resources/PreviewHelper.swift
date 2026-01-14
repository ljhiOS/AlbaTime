//
//  PreviewHelper.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftData
import SwiftUI

@MainActor
struct PreviewHelper {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true) // 메모리에만 저장 (앱 끄면 사라짐)
        let container = try! ModelContainer(for: Workplace.self, configurations: config)
        
        // 1. 가짜 가게 생성
        let starbucks = Workplace(
            name: "스타벅스 강남점",
            hourlyWage: 10000,
            defaultDays: "월,수,금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(15, 0)
        )
        container.mainContext.insert(starbucks)
        
        return container
    }()
}
