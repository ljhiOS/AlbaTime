//
//  AlbaTimeApp.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        AnalyticsConsentStore.applyStoredConsent()
        return true
    }
}

@main
struct AlbaTimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 트래커 주입
    private let analyticsTracker = FirebaseAnalyticsTracker()

    //알림 허용
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.analyticsTracker, analyticsTracker)
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
