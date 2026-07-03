//
//  AppWriteCoordinator.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

// TODO: WorkPlace 설계 구조에 맞춰 전체 프로젝트 설계 변경 완료시 삭제
// 저장 후처리

struct AppWriteCoordinator {
    @MainActor
    func commit(context: ModelContext, affectedWorkPlace: WorkPlace? = nil) throws {
        try context.save()

        if let affectedWorkPlace {
            NotificationManager.shared.refreshNotifications(for: affectedWorkPlace)
        }

        let workPlaces = try context.fetch(FetchDescriptor<WorkPlace>())
        NextShiftSyncService.sync(workPlaces: workPlaces)
    }

    @MainActor
    func delete(workPlace: WorkPlace, context: ModelContext) throws {
        NotificationManager.shared.removeNotifications(for: workPlace)
        context.delete(workPlace)
        try commit(context: context)
    }
}
