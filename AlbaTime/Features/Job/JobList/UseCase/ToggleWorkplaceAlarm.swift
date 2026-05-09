//
//  ToggleWorkpaceAlarm.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation
import SwiftData

enum ToggleWorkplaceAlarmError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "알람 설정 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkplaceAlarm {
    private let appWriteCoordinator = AppWriteCoordinator()

    @MainActor
    func execute(workplace: Workplace, context: ModelContext) throws {
        do {
            workplace.isAlarmEnabled.toggle()
            try appWriteCoordinator.commit(context: context, affectedWorkplace: workplace)
        } catch {
            throw ToggleWorkplaceAlarmError.saveFailed(error.localizedDescription)
        }
    }
}
