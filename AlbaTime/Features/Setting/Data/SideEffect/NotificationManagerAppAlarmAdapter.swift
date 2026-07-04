//
//  NotificationManagerAppAlarmAdapter.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
struct NotificationManagerAppAlarmAdapter: AppAlarmScheduling {
    private let manager: NotificationManager

    init(manager: NotificationManager = .shared) {
        self.manager = manager
    }

    func refreshEnabledWorkPlaceNotifications(workPlaces: [WorkPlace]) {
        for workPlace in workPlaces where workPlace.isAlarmEnabled {
            manager.refreshNotifications(for: workPlace)
        }
    }

    func removeAllNotifications() {
        manager.removeAllNotifications()
    }
}
