//
//  ToggleWorkpaceAlarm.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

enum ToggleWorkplaceAlarmError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "알람 설정 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkplaceAlarm: WorkplaceAlarmToggling {
    private let writer: any WorkplaceAlarmStateWriting

    init(writer: any WorkplaceAlarmStateWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workplaceID: UUID) throws {
        do {
            try writer.toggleAlarm(id: workplaceID)
        } catch {
            throw ToggleWorkplaceAlarmError.saveFailed(error.localizedDescription)
        }
    }
}
