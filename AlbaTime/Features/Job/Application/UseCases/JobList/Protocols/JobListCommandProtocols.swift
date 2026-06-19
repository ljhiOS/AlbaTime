//
//  JobListCommandProtocols.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol WorkplaceDeleting {
    func execute(workplaceID: UUID) throws
}

@MainActor
protocol WorkplaceAlarmToggling {
    func execute(workplaceID: UUID) throws
}

@MainActor
protocol WorkplacePinToggling {
    func execute(workplaceID: UUID) throws
}

@MainActor
protocol WorkplaceMemoUpdating {
    func execute(workplaceID: UUID, memo: String) throws
}
