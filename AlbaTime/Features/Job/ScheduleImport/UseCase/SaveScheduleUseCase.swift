//
//  SaveScheduleUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/3/26.
//

import Foundation
import SwiftData

enum SaveScheduleError: LocalizedError {
    case missingJob

    var errorDescription: String? {
        switch self {
        case .missingJob:
            return "저장할 근무지 정보가 없습니다."
        }
    }
}

struct SaveScheduleUseCase {
    private let appWriteCoordinator = AppWriteCoordinator()
    private let workScheduleFactory = WorkScheduleFactory()
    
    @MainActor
    func execute(
        _ command: SaveScheduleCommand,
        context: ModelContext
    ) throws {
        switch command {
        case .editDraft(let job, let draft):
            try saveEditDraft(
                job: job,
                draft: draft,
                context: context
            )
        }
    }

    @MainActor
    private func saveEditDraft(
        job: Workplace?,
        draft: ScheduleEditDraft,
        context: ModelContext
    ) throws {
        guard let job else {
            throw SaveScheduleError.missingJob
        }

        let aiImportBatchID = UUID().uuidString

        if job.modelContext == nil {
            context.insert(job)
        }

        for item in draft.items {
            switch item.changeState {
            case .clean:
                continue

            case .deleted:
                if let existing = findExistingSchedule(for: item, in: job) {
                    job.workSchedules.removeAll { $0.id == existing.id }
                    context.delete(existing)
                }

            case .inserted:
                if draft.mode == .existingJobAIImport {
                    deleteExistingSchedules(
                        on: item.date,
                        targetWeekStart: draft.targetWeekStart,
                        in: job,
                        context: context
                    )
                }
                let schedule = workScheduleFactory.make(
                    from: item,
                    targetWeekStart: draft.targetWeekStart,
                    aiImportBatchID: aiImportBatchID
                )
                schedule.workplace = job
                job.workSchedules.append(schedule)
                context.insert(schedule)

            case .updated:
                if let existing = findExistingSchedule(for: item, in: job) {
                    workScheduleFactory.apply(
                        item,
                        to: existing,
                        targetWeekStart: draft.targetWeekStart
                    )
                } else {
                    let schedule = workScheduleFactory.make(
                        from: item,
                        targetWeekStart: draft.targetWeekStart,
                        aiImportBatchID: aiImportBatchID
                    )
                    schedule.workplace = job
                    job.workSchedules.append(schedule)
                    context.insert(schedule)
                }
            }
        }

        try appWriteCoordinator.commit(context: context, affectedWorkplace: job)
    }

    private func findExistingSchedule(
        for item: ScheduleEditItem,
        in job: Workplace
    ) -> WorkSchedule? {
        if let originalScheduleID = item.originalScheduleID,
           let byID = job.workSchedules.first(where: { $0.id == originalScheduleID }) {
            return byID
        }

        return job.workSchedules.first {
            Calendar.current.isDate($0.date, inSameDayAs: item.date)
        }
    }

    @MainActor
    private func deleteExistingSchedules(
        on originalDate: Date,
        targetWeekStart: Date?,
        in job: Workplace,
        context: ModelContext
    ) {
        let mappedDate = workScheduleFactory.mappedDate(
            originalDate: originalDate,
            targetWeekStart: targetWeekStart
        )
        let targets = job.workSchedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: mappedDate)
        }

        for target in targets {
            job.workSchedules.removeAll { $0.id == target.id }
            context.delete(target)
        }
    }
}
