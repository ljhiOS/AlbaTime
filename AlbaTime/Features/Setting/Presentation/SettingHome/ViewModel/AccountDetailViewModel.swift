//
//  AccountDetailViewModel.swift
//  AlbaTime
//
//  Created by Codex on 7/4/26.
//

import Foundation

@MainActor
final class AccountDetailViewModel: ObservableObject {
    private let appAlarmToggling: any AppAlarmToggling

    init(appAlarmToggling: any AppAlarmToggling) {
        self.appAlarmToggling = appAlarmToggling
    }

    func toggleAppAlarm(isEnabled: Bool, workPlaces: [WorkPlace]) {
        appAlarmToggling.execute(
            isEnabled: isEnabled,
            workPlaces: workPlaces
        )
    }
}
