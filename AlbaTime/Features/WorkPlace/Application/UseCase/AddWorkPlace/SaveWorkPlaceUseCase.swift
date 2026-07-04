//
//  SaveWorkPlaceUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation

// AddWorkPlace 저장 UseCase에 전달되는 저장 명령입니다.
enum SaveWorkPlaceCommand {
    // 신규/수정 근무지 저장 요청입니다.
    case workPlaceDraft(
        editingWorkPlaceID: UUID?,
        draft: WorkPlaceDraft,
        scheduleImportDraft: ScheduleImportDraft,
        initialDefaultRestTime: Int?
    )
}

struct SaveWorkPlaceUseCase: WorkPlaceSaving {
    private let workPlaceSaveValidator = WorkPlaceSaveValidator()
    private let writer: any WorkPlaceDraftPersistenceWriting

    init(writer: any WorkPlaceDraftPersistenceWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(_ command: SaveWorkPlaceCommand) throws {
        switch command {
        case .workPlaceDraft(
            let editingWorkPlaceID,
            let draft,
            let scheduleImportDraft,
            let initialDefaultRestTime
        ):
            try saveWorkPlaceDraft(
                editingWorkPlaceID: editingWorkPlaceID,
                draft: draft,
                scheduleImportDraft: scheduleImportDraft,
                initialDefaultRestTime: initialDefaultRestTime
            )
        }
    }
}

private extension SaveWorkPlaceUseCase {
    var days: [String] {
        ["월", "화", "수", "목", "금", "토", "일"]
    }

    @MainActor
    func saveWorkPlaceDraft(
        editingWorkPlaceID: UUID?,
        draft: WorkPlaceDraft,
        scheduleImportDraft: ScheduleImportDraft,
        initialDefaultRestTime: Int?
    ) throws {
        let orderedSchedules = orderedRegularSchedules(from: draft)
        let initialImportedSchedules = scheduleImportDraft.schedules
            .filter { $0.changeState != .deleted }

        try workPlaceSaveValidator.validate(draft: draft)

        switch draft.workType {
        case .fixed:
            try SaveFixedWorkPlace(
                workPlaceSaveValidator: workPlaceSaveValidator,
                writer: writer
            ).execute(
                editingWorkPlaceID: editingWorkPlaceID,
                draft: draft,
                orderedRegularSchedules: orderedSchedules,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )

        case .flexible:
            try SaveFlexibleWorkPlace(writer: writer).execute(
                editingWorkPlaceID: editingWorkPlaceID,
                draft: draft,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        }
    }

    func orderedRegularSchedules(from draft: WorkPlaceDraft) -> [RegularScheduleDraft] {
        draft.regularSchedules.sorted { left, right in
            let leftIndex = days.firstIndex(of: left.dayOfWeek) ?? 0
            let rightIndex = days.firstIndex(of: right.dayOfWeek) ?? 0
            return leftIndex < rightIndex
        }
    }
}

