//
//  AnalyticsTracking.swift
//  AlbaTime
//
//  Created by 이준희 on 8/2/26.
//

import Foundation

protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

struct NoopAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
}
