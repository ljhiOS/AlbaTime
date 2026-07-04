//
//  WorkPlaceListCommandProtocols.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol WorkPlaceDeleting {
    func execute(workPlaceID: UUID) throws
}

@MainActor
protocol WorkPlaceAlarmToggling {
    func execute(workPlaceID: UUID) throws
}

@MainActor
protocol WorkPlacePinToggling {
    func execute(workPlaceID: UUID) throws
}

@MainActor
protocol WorkPlaceMemoUpdating {
    func execute(workPlaceID: UUID, memo: String) throws
}
