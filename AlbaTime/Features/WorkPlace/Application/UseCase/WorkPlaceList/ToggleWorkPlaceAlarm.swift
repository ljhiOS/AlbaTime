//
//  ToggleWorkPlaceAlarm.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

enum ToggleWorkPlaceAlarmError: LocalizedError {
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "알람 설정 저장 중 오류가 발생했어요. \(message)"
        }
    }
}

struct ToggleWorkPlaceAlarm: WorkPlaceAlarmToggling {
    private let writer: any WorkPlaceAlarmStateWriting

    init(writer: any WorkPlaceAlarmStateWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(workPlaceID: UUID) throws {
        do {
            try writer.toggleAlarm(id: workPlaceID)
        } catch {
            throw ToggleWorkPlaceAlarmError.saveFailed(error.localizedDescription)
        }
    }
}
