//
//  WorkPlaceSaving.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol WorkPlaceSaving {
    func execute(_ command: SaveWorkPlaceCommand) throws
}
