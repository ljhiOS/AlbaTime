//
//  SaveJobUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation

struct SaveJobUseCase: JobSaving {
    private let jobSaveValidator = JobSaveValidator()
    private let writer: any JobDraftPersistenceWriting

    init(writer: any JobDraftPersistenceWriting) {
        self.writer = writer
    }

    @MainActor
    func execute(_ command: JobSaveCommand) throws {
        switch command {
        case .jobDraft(
            let editingJobID,
            let draft,
            let scheduleImportDraft,
            let initialDefaultRestTime
        ):
            try saveJobDraft(
                editingJobID: editingJobID,
                draft: draft,
                scheduleImportDraft: scheduleImportDraft,
                initialDefaultRestTime: initialDefaultRestTime
            )
        }
    }
}

private extension SaveJobUseCase {
    var days: [String] {
        ["월", "화", "수", "목", "금", "토", "일"]
    }

    @MainActor
    func saveJobDraft(
        editingJobID: UUID?,
        draft: JobDraft,
        scheduleImportDraft: ScheduleImportDraft,
        initialDefaultRestTime: Int?
    ) throws {
        let orderedSchedules = orderedRegularSchedules(from: draft)
        let initialImportedSchedules = scheduleImportDraft.schedules
            .filter { $0.changeState != .deleted }

        try jobSaveValidator.validate(draft: draft)

        switch draft.workType {
        case .fixed:
            try SaveFixedJob(
                jobSaveValidator: jobSaveValidator,
                writer: writer
            ).execute(
                editingJobID: editingJobID,
                draft: draft,
                orderedRegularSchedules: orderedSchedules,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )

        case .flexible:
            try SaveFlexibleJob(writer: writer).execute(
                editingJobID: editingJobID,
                draft: draft,
                initialImportedSchedules: initialImportedSchedules,
                initialDefaultRestTime: initialDefaultRestTime
            )
        }
    }

    func orderedRegularSchedules(from draft: JobDraft) -> [RegularScheduleDraft] {
        draft.regularSchedules.sorted { left, right in
            let leftIndex = days.firstIndex(of: left.dayOfWeek) ?? 0
            let rightIndex = days.firstIndex(of: right.dayOfWeek) ?? 0
            return leftIndex < rightIndex
        }
    }
}

