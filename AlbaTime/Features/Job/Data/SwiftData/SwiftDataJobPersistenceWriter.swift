//
//  SwiftDataJobPersistenceWriter.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation
import SwiftData

enum JobPersistenceError: LocalizedError {
    case missingWorkplace

    var errorDescription: String? {
        switch self {
        case .missingWorkplace:
            return "저장할 근무지 정보가 없습니다."
        }
    }
}

@MainActor
struct SwiftDataJobPersistenceWriter: JobPersistenceWriting {
    private let context: ModelContext
    private let notificationScheduler: any WorkplaceNotificationScheduling
    private let workplaceSyncing: any WorkplaceSyncing
    private let breakTimeApplier = ApplyBreakTime()
    private let workScheduleFactory = WorkScheduleFactory()

    init(
        context: ModelContext,
        notificationScheduler: any WorkplaceNotificationScheduling = NotificationManagerJobAdapter(),
        workplaceSyncing: any WorkplaceSyncing = NextShiftWorkplaceSyncing()
    ) {
        self.context = context
        self.notificationScheduler = notificationScheduler
        self.workplaceSyncing = workplaceSyncing
    }

    func saveJobDraft(_ request: JobDraftPersistenceRequest) throws {
        let job = try workplace(for: request.editingJobID) ?? Workplace(
            name: "",
            hourlyWage: 0,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: request.draft.workType
        )

        if job.modelContext == nil {
            context.insert(job)
        }

        applyBaseDraft(request.draft, to: job)

        switch request.draft.workType {
        case .fixed:
            replaceRegularSchedules(
                request.orderedRegularSchedules,
                on: job
            )

        case .flexible:
            job.targetWeeklyCount = request.draft.targetWeeklyCount
            job.expectedDailyHours = request.draft.expectedDailyHours
            deleteRegularSchedules(on: job)
        }

        appendInitialAISchedulesIfNeeded(
            request.initialImportedSchedules,
            to: job,
            isNewJob: request.editingJobID == nil
        )

        breakTimeApplier.breakTime(
            job: job,
            initialDefaultRestTime: request.initialDefaultRestTime
        )

        try commit(affectedWorkplace: job)
    }

    func saveScheduleDraft(_ request: ScheduleDraftPersistenceRequest) throws {
        guard let job = try workplace(for: request.jobID) else {
            throw JobPersistenceError.missingWorkplace
        }

        let aiImportBatchID = UUID().uuidString

        for item in request.draft.items {
            switch item.changeState {
            case .clean:
                continue

            case .deleted:
                if let existing = findExistingSchedule(for: item, in: job) {
                    job.workSchedules.removeAll { $0.id == existing.id }
                    context.delete(existing)
                }

            case .inserted:
                if request.draft.state == .existingJobAIImport {
                    deleteExistingSchedules(
                        on: item.date,
                        targetWeekStart: request.draft.targetWeekStart,
                        in: job
                    )
                }
                let schedule = workScheduleFactory.make(
                    from: item,
                    targetWeekStart: request.draft.targetWeekStart,
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
                        targetWeekStart: request.draft.targetWeekStart
                    )
                } else {
                    let schedule = workScheduleFactory.make(
                        from: item,
                        targetWeekStart: request.draft.targetWeekStart,
                        aiImportBatchID: aiImportBatchID
                    )
                    schedule.workplace = job
                    job.workSchedules.append(schedule)
                    context.insert(schedule)
                }
            }
        }

        try commit(affectedWorkplace: job)
    }

    func deleteWorkplace(id: UUID) throws {
        guard let workplace = try workplace(for: id) else {
            throw JobPersistenceError.missingWorkplace
        }

        notificationScheduler.removeNotifications(for: workplace)
        context.delete(workplace)
        try commit(affectedWorkplace: nil)
    }

    func toggleAlarm(id: UUID) throws {
        guard let workplace = try workplace(for: id) else {
            throw JobPersistenceError.missingWorkplace
        }

        workplace.isAlarmEnabled.toggle()
        try commit(affectedWorkplace: workplace)
    }

    func togglePin(id: UUID) throws {
        guard let workplace = try workplace(for: id) else {
            throw JobPersistenceError.missingWorkplace
        }

        workplace.isPinned.toggle()
        try commit(affectedWorkplace: nil)
    }

    func updateMemo(id: UUID, memo: String) throws {
        guard let workplace = try workplace(for: id) else {
            throw JobPersistenceError.missingWorkplace
        }

        workplace.defaultMemo = memo
        try commit(affectedWorkplace: nil)
    }
}

private extension SwiftDataJobPersistenceWriter {
    func workplace(for id: UUID?) throws -> Workplace? {
        guard let id else { return nil }
        var descriptor = FetchDescriptor<Workplace>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func applyBaseDraft(_ draft: JobDraft, to job: Workplace) {
        job.name = draft.name.trimmingCharacters(in: .whitespaces)
        job.hourlyWage = draft.hourlyWage
        job.defaultRestTime = draft.defaultRestTime
        job.defaultMemo = draft.defaultMemo.isEmpty ? nil : draft.defaultMemo
        job.taxType = draft.taxType
        job.allowanceType = draft.allowanceType
        job.workType = draft.workType
    }

    func replaceRegularSchedules(
        _ drafts: [RegularScheduleDraft],
        on job: Workplace
    ) {
        deleteRegularSchedules(on: job)

        for draft in drafts {
            let schedule = RegularSchedule(
                dayOfWeek: draft.dayOfWeek,
                startTime: draft.startTime,
                endTime: draft.endTime,
                breakTime: draft.breakTime
            )

            schedule.workplace = job
            job.regularSchedules.append(schedule)
            context.insert(schedule)
        }

        job.targetWeeklyCount = nil
        job.expectedDailyHours = nil
        job.defaultDays = drafts.map(\.dayOfWeek).joined(separator: ",")

        if let firstSchedule = drafts.first {
            job.defaultStartTime = firstSchedule.startTime
            job.defaultEndTime = firstSchedule.endTime
        }
    }

    func deleteRegularSchedules(on job: Workplace) {
        let schedulesToDelete = job.regularSchedules
        job.regularSchedules.removeAll()

        for schedule in schedulesToDelete {
            context.delete(schedule)
        }
    }

    func appendInitialAISchedulesIfNeeded(
        _ items: [ScheduleDraftItem],
        to job: Workplace,
        isNewJob: Bool
    ) {
        guard isNewJob else { return }

        let batchID = UUID().uuidString

        for item in items {
            let schedule = workScheduleFactory.make(
                from: item,
                aiImportBatchID: batchID
            )
            schedule.workplace = job
            job.workSchedules.append(schedule)
            context.insert(schedule)
        }
    }

    func findExistingSchedule(
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

    func deleteExistingSchedules(
        on originalDate: Date,
        targetWeekStart: Date?,
        in job: Workplace
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

    func commit(affectedWorkplace: Workplace?) throws {
        try context.save()

        if let affectedWorkplace {
            notificationScheduler.refreshNotifications(for: affectedWorkplace)
        }

        let workplaces = try context.fetch(FetchDescriptor<Workplace>())
        workplaceSyncing.sync(workplaces: workplaces)
    }
}
