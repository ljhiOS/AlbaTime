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
        }
        .modelContainer(for: [
            WorkPlace.self,
            MonthlyRecord.self,
            RegularSchedule.self,
            WorkSchedule.self,
            WorkRecord.self,
            WorkTimePreset.self
        ])
    }
}
