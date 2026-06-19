//
//  ScheduleSaving.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol ScheduleSaving {
    func execute(_ command: SaveScheduleCommand) throws
}
