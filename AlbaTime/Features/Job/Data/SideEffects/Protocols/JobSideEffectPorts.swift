//
//  JobSideEffectPorts.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol WorkPlaceNotificationScheduling {
    func refreshNotifications(for workPlace: WorkPlace)
    func removeNotifications(for workPlace: WorkPlace)
}

@MainActor
protocol WorkPlaceSyncing {
    func sync(workPlaces: [WorkPlace])
}

