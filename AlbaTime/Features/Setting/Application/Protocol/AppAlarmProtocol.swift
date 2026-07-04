//
//  AppAlarmProtocol.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
protocol AppAlarmToggling {
    func execute(isEnabled: Bool, workPlaces: [WorkPlace])
}

@MainActor
protocol AppAlarmScheduling {
    func refreshEnabledWorkPlaceNotifications(workPlaces: [WorkPlace])
    func removeAllNotifications()
}
