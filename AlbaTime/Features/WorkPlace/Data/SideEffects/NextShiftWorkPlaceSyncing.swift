//
//  NextShiftWorkPlaceSyncing.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct NextShiftWorkPlaceSyncing: WorkPlaceSyncing {
    func sync(workPlaces: [WorkPlace]) {
        NextShiftSyncService.sync(workPlaces: workPlaces)
    }
}

