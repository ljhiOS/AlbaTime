//
//  SettingFeatureComposition.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
enum SettingFeatureComposition {
    static func makeAppAlarmToggling() -> any AppAlarmToggling {
        ToggleAppAlarm(
            scheduler: NotificationManagerAppAlarmAdapter()
        )
    }
}
