//
//  NextShiftWorkplaceSyncing.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct NextShiftWorkplaceSyncing: WorkplaceSyncing {
    func sync(workplaces: [Workplace]) {
        NextShiftSyncService.sync(workplaces: workplaces)
    }
}

