//
//  NotificationManagerJobAdapter.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
struct NotificationManagerJobAdapter: WorkPlaceNotificationScheduling {
    private let manager: NotificationManager

    init(manager: NotificationManager = .shared) {
        self.manager = manager
    }

    func refreshNotifications(for workPlace: WorkPlace) {
        manager.refreshNotifications(for: workPlace)
    }

    func removeNotifications(for workPlace: WorkPlace) {
        manager.removeNotifications(for: workPlace)
    }
}
