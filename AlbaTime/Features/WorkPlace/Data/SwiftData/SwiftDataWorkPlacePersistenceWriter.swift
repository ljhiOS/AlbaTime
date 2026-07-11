//
//  SwiftDataWorkPlacePersistenceWriter.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation
import SwiftData

enum WorkPlacePersistenceError: LocalizedError {
    case missingWorkPlace

    var errorDescription: String? {
        switch self {
        case .missingWorkPlace:
            return "저장할 근무지 정보가 없어요."
        }
    }
}

@MainActor
struct SwiftDataWorkPlacePersistenceWriter: WorkPlacePersistenceWriting {
    private let context: ModelContext
    private let notificationScheduler: any WorkPlaceNotificationScheduling
    private let workPlaceSyncing: any WorkPlaceSyncing
    private let breakTimeApplier = ApplyBreakTime()
    private let workScheduleFactory = WorkScheduleFactory()

    init(
        context: ModelContext,
        notificationScheduler: any WorkPlaceNotificationScheduling = NotificationManagerWorkPlaceAdapter(),
        workPlaceSyncing: any WorkPlaceSyncing = NextShiftWorkPlaceSyncing()
    ) {
        self.context = context
        self.notificationScheduler = notificationScheduler
        self.workPlaceSyncing = workPlaceSyncing
    }

    func saveWorkPlaceDraft(_ request: PersistWorkPlaceDraftRequest) throws {
        let workPlace = try workPlace(for: request.editingWorkPlaceID) ?? WorkPlace(
            name: "",
            hourlyWage: 0,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: request.draft.workType
        )

        if workPlace.modelContext == nil {
            context.insert(workPlace)
        }

        applyBaseDraft(request.draft, to: workPlace)

        switch request.draft.workType {
        case .fixed:
            replaceRegularSchedules(
                request.orderedRegularSchedules,
                on: workPlace
            )

        case .flexible:
            workPlace.targetWeeklyCount = request.draft.targetWeeklyCount
            workPlace.expectedDailyHours = request.draft.expectedDailyHours
            deleteRegularSchedules(on: workPlace)
        }

        appendInitialAISchedulesIfNeeded(
            request.initialImportedSchedules,
            to: workPlace,
            isNewWorkPlace: request.editingWorkPlaceID == nil
        )

        breakTimeApplier.breakTime(
            workPlace: workPlace,
            initialDefaultRestTime: request.initialDefaultRestTime
        )

        try commit(affectedWorkPlace: workPlace)
    }

    func saveScheduleDraft(_ request: ScheduleDraftPersistenceRequest) throws {
        guard let workPlace = try workPlace(for: request.workPlaceID) else {
            throw WorkPlacePersistenceError.missingWorkPlace
        }

        let aiImportBatchID = UUID().uuidString

        for item in request.draft.items {
            switch item.changeState {
            case .clean:
                continue

            case .deleted:
                if let existing = findExistingSchedule(for: item, in: workPlace) {
                    workPlace.workSchedules.removeAll { $0.id == existing.id }
                    context.delete(existing)
                }

            case .inserted:
                if request.draft.state == .existingWorkPlaceAIImport {
                    deleteExistingSchedules(
                        on: item.date,
                        targetWeekStart: request.draft.targetWeekStart,
                        in: workPlace
                    )
                }
                let schedule = workScheduleFactory.make(
                    from: item,
                    targetWeekStart: request.draft.targetWeekStart,
                    aiImportBatchID: aiImportBatchID
                )
                schedule.workPlace = workPlace
                workPlace.workSchedules.append(schedule)
                context.insert(schedule)

            case .updated:
                if let existing = findExistingSchedule(for: item, in: workPlace) {
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
                    schedule.workPlace = workPlace
                    workPlace.workSchedules.append(schedule)
                    context.insert(schedule)
                }
            }
        }

        try commit(affectedWorkPlace: workPlace)
    }

    func deleteWorkPlace(id: UUID) throws {
        guard let workPlace = try workPlace(for: id) else {
            throw WorkPlacePersistenceError.missingWorkPlace
        }

        notificationScheduler.removeNotifications(for: workPlace)
        context.delete(workPlace)
        try commit(affectedWorkPlace: nil)
    }

    func toggleAlarm(id: UUID) throws {
        guard let workPlace = try workPlace(for: id) else {
            throw WorkPlacePersistenceError.missingWorkPlace
        }

        workPlace.isAlarmEnabled.toggle()
        try commit(affectedWorkPlace: workPlace)
    }

    func togglePin(id: UUID) throws {
        guard let workPlace = try workPlace(for: id) else {
            throw WorkPlacePersistenceError.missingWorkPlace
        }

        workPlace.isPinned.toggle()
        try commit(affectedWorkPlace: nil)
    }

    func updateMemo(id: UUID, memo: String) throws {
        guard let workPlace = try workPlace(for: id) else {
            throw WorkPlacePersistenceError.missingWorkPlace
        }

        workPlace.defaultMemo = memo
        try commit(affectedWorkPlace: nil)
    }
}

private extension SwiftDataWorkPlacePersistenceWriter {
    func workPlace(for id: UUID?) throws -> WorkPlace? {
        guard let id else { return nil }
        var descriptor = FetchDescriptor<WorkPlace>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func applyBaseDraft(_ draft: WorkPlaceDraft, to workPlace: WorkPlace) {
        workPlace.name = draft.name.trimmingCharacters(in: .whitespaces)
        workPlace.hourlyWage = draft.hourlyWage
        workPlace.defaultRestTime = draft.defaultRestTime
        workPlace.defaultMemo = draft.defaultMemo.isEmpty ? nil : draft.defaultMemo
        workPlace.taxType = draft.taxType
        workPlace.allowanceType = draft.allowanceType
        workPlace.workType = draft.workType
    }

    func replaceRegularSchedules(
        _ drafts: [RegularScheduleDraft],
        on workPlace: WorkPlace
    ) {
        deleteRegularSchedules(on: workPlace)

        for draft in drafts {
            let schedule = RegularSchedule(
                dayOfWeek: draft.dayOfWeek,
                startTime: draft.startTime,
                endTime: draft.endTime,
                breakTime: draft.breakTime
            )

            schedule.workPlace = workPlace
            workPlace.regularSchedules.append(schedule)
            context.insert(schedule)
        }

        workPlace.targetWeeklyCount = nil
        workPlace.expectedDailyHours = nil
        workPlace.defaultDays = drafts.map(\.dayOfWeek).joined(separator: ",")

        if let firstSchedule = drafts.first {
            workPlace.defaultStartTime = firstSchedule.startTime
            workPlace.defaultEndTime = firstSchedule.endTime
        }
    }

    func deleteRegularSchedules(on workPlace: WorkPlace) {
        let schedulesToDelete = workPlace.regularSchedules
        workPlace.regularSchedules.removeAll()

        for schedule in schedulesToDelete {
            context.delete(schedule)
        }
    }

    func appendInitialAISchedulesIfNeeded(
        _ items: [ScheduleDraftItem],
        to workPlace: WorkPlace,
        isNewWorkPlace: Bool
    ) {
        guard isNewWorkPlace else { return }

        let batchID = UUID().uuidString

        for item in items {
            let schedule = workScheduleFactory.make(
                from: item,
                aiImportBatchID: batchID
            )
            schedule.workPlace = workPlace
            workPlace.workSchedules.append(schedule)
            context.insert(schedule)
        }
    }

    func findExistingSchedule(
        for item: ScheduleEditItem,
        in workPlace: WorkPlace
    ) -> WorkSchedule? {
        if let originalScheduleID = item.originalScheduleID,
           let byID = workPlace.workSchedules.first(where: { $0.id == originalScheduleID }) {
            return byID
        }

        return workPlace.workSchedules.first {
            Calendar.current.isDate($0.date, inSameDayAs: item.date)
        }
    }

    func deleteExistingSchedules(
        on originalDate: Date,
        targetWeekStart: Date?,
        in workPlace: WorkPlace
    ) {
        let mappedDate = workScheduleFactory.mappedDate(
            originalDate: originalDate,
            targetWeekStart: targetWeekStart
        )
        let targets = workPlace.workSchedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: mappedDate)
        }

        for target in targets {
            workPlace.workSchedules.removeAll { $0.id == target.id }
            context.delete(target)
        }
    }

    func commit(affectedWorkPlace: WorkPlace?) throws {
        try context.save()

        if let affectedWorkPlace {
            notificationScheduler.refreshNotifications(for: affectedWorkPlace)
        }

        let workPlaces = try context.fetch(FetchDescriptor<WorkPlace>())
        workPlaceSyncing.sync(workPlaces: workPlaces)
    }
}
