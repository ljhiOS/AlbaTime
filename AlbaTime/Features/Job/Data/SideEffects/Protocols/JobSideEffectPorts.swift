//
//  JobSideEffectPorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol WorkplaceNotificationScheduling {
    func refreshNotifications(for workplace: Workplace)
    func removeNotifications(for workplace: Workplace)
}

@MainActor
protocol WorkplaceSyncing {
    func sync(workplaces: [Workplace])
}

