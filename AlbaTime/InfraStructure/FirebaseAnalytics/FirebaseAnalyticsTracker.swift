//
//  FirebaseAnalyticsTracker.swift
//  AlbaTime
//
//  Created by 이준희 on 8/2/26.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

enum AnalyticsConsentStore {
    static let decisionKey = "analyticsConsentDecided"
    static let grantedKey = "analyticsConsentGranted"

    static var hasDecided: Bool {
        UserDefaults.standard.object(forKey: decisionKey) != nil
    }

    static var isGranted: Bool {
        UserDefaults.standard.bool(forKey: grantedKey)
    }

    static func applyStoredConsent() {
        setAnalyticsCollectionEnabled(hasDecided && isGranted)
    }

    static func setConsent(_ isGranted: Bool) {
        UserDefaults.standard.set(true, forKey: decisionKey)
        UserDefaults.standard.set(isGranted, forKey: grantedKey)
        setAnalyticsCollectionEnabled(isGranted)
    }

    private static func setAnalyticsCollectionEnabled(_ isEnabled: Bool) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
    }
}

struct FirebaseAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        switch event {
        case .scheduleDetailViewed:
            Analytics.logEvent("schedule_detail_viewed", parameters: nil)

        case .workplaceEdit:
            Analytics.logEvent("workplace_edit", parameters: nil)

        case .fixedWorkplaceSaved:
            Analytics.logEvent("fixed_workplace_saved", parameters: nil)

        case .fixedWorkplaceCreateOpened:
            Analytics.logEvent("fixed_workplace_create_opened", parameters: nil)

        case .flexibleWorkplaceSaved:
            Analytics.logEvent("flexible_workplace_saved", parameters: nil)

        case .flexibleWorkplaceCreateOpened:
            Analytics.logEvent("flexible_workplace_create_opened", parameters: nil)

        case .aiScheduleOpened:
            Analytics.logEvent("ai_schedule_opened", parameters: nil)

        case .aiScheduleSaved:
            Analytics.logEvent("ai_schedule_saved", parameters: nil)

        case .manualScheduleClick:
            Analytics.logEvent("manual_schedule_click", parameters: nil)

        case .manualScheduleSaved:
            Analytics.logEvent("manual_schedule_saved", parameters: nil)

        case .monthlyIncomeSaved:
            Analytics.logEvent("monthly_income_saved", parameters: nil)

        case .salaryModeChanged:
            Analytics.logEvent("salary_mode_changed", parameters: nil)

        case .workTimeChanged:
            Analytics.logEvent("work_time_changed", parameters: nil)
        }
    }
}
