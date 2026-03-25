//
//  AppWriteCoordinator.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

struct AppWriteCoordinator {
    @MainActor
    func commit(context: ModelContext, affectedWorkplace: Workplace? = nil) throws {
        try context.save()
        
        if let affectedWorkplace {
            NotificationManager.shared.refreshNotifications(for: affectedWorkplace)
        }
        
        let workplaces = try context.fetch(FetchDescriptor<Workplace>())
        NextShiftSyncService.sync(workplaces: workplaces)
    }
}
