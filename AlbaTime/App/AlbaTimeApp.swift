//
//  AlbaTimeApp.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

@main
struct AlbaTimeApp: App {
    //알림 허용
    init() {
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            Workplace.self,
            MonthlyRecord.self,
            RegularSchedule.self,
            WorkSchedule.self,
            WorkTimePreset.self
        ])
    }
}
