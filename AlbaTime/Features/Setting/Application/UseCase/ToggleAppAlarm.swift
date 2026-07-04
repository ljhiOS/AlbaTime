//
//  ToggleAppAlarm.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
struct ToggleAppAlarm: AppAlarmToggling {
    private let scheduler: any AppAlarmScheduling

    init(scheduler: any AppAlarmScheduling) {
        self.scheduler = scheduler
    }

    func execute(isEnabled: Bool, workPlaces: [WorkPlace]) {
        if isEnabled {
            scheduler.refreshEnabledWorkPlaceNotifications(workPlaces: workPlaces)
        } else {
            scheduler.removeAllNotifications()
        }
    }
}
