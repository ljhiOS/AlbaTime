//
//  AnalyticsEnvironment.swift
//  AlbaTime
//
//  Created by 이준희 on 8/2/26.
//

import SwiftUI

private struct AnalyticsTrackerKey: EnvironmentKey {
    static let defaultValue: any AnalyticsTracking = NoopAnalyticsTracker()
}

extension EnvironmentValues {
    var analyticsTracker: any AnalyticsTracking {
        get { self[AnalyticsTrackerKey.self] }
        set { self[AnalyticsTrackerKey.self] = newValue }
    }
}
