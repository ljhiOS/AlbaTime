//
//  NotificationManagerJobAdapter.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
struct NotificationManagerJobAdapter: WorkplaceNotificationScheduling {
    private let manager: NotificationManager

    init(manager: NotificationManager = .shared) {
        self.manager = manager
    }

    func refreshNotifications(for workplace: Workplace) {
        manager.refreshNotifications(for: workplace)
    }

    func removeNotifications(for workplace: Workplace) {
        manager.removeNotifications(for: workplace)
    }
}
