//
//  SaveJobUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation
import SwiftData

struct SaveJobUseCase {
    private let jobSaveValidator = JobSaveValidator()
    private let applyBreakTime = ApplyBreakTime()
    private let appWriteCoordinator = AppWriteCoordinator()
    private let workScheduleFactory = WorkScheduleFactory()

    @MainActor
    func execute(
        _ command: JobSaveCommand,
        context: ModelContext
    ) throws {
        switch command {
        case .jobDraft(let session, let initialDefaultRestTime):
            try saveJobDraft(
                session: session,
                initialDefaultRestTime: initialDefaultRestTime,
                context: context
            )
        }
    }

    @MainActor
    private func saveJobDraft(
        session: JobEditingSession,
        initialDefaultRestTime: Int?,
        context: ModelContext
    ) throws {
        let job = applyDraftToJob(
            session: session,
            context: context
        )

        switch session.jobDraft.workType {
        case .fixed:
            try SaveFixedJob(
                jobSaveValidator: jobSaveValidator,
                applyBreakTime: applyBreakTime,
                appWriteCoordinator: appWriteCoordinator
            ).execute(
                job: job,
                initialDefaultRestTime: initialDefaultRestTime,
                context: context
            )

        case .flexible:
            try SaveFlexibleJob(
                jobSaveValidator: jobSaveValidator,
                applyBreakTime: applyBreakTime,
                appWriteCoordinator: appWriteCoordinator
            ).execute(
                job: job,
                targetWeeklyCount: session.jobDraft.targetWeeklyCount,
                expectedDailyHours: session.jobDraft.expectedDailyHours,
                initialDefaultRestTime: initialDefaultRestTime,
                context: context
            )
        }
    }
}

private extension SaveJobUseCase {
    var days: [String] {
        ["월", "화", "수", "목", "금", "토", "일"]
    }

    @MainActor
    func applyDraftToJob(
        session: JobEditingSession,
        context: ModelContext
    ) -> Workplace {
        let job = session.editingJob ?? Workplace(
            name: "",
            hourlyWage: 0,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: session.jobDraft.workType
        )

        job.name = session.jobDraft.name.trimmingCharacters(in: .whitespaces)
        job.hourlyWage = session.jobDraft.hourlyWage
        job.defaultRestTime = session.jobDraft.defaultRestTime
        job.defaultMemo = session.jobDraft.defaultMemo.isEmpty ? nil : session.jobDraft.defaultMemo
        job.taxType = session.jobDraft.taxType
        job.allowanceType = session.jobDraft.allowanceType
        job.workType = session.jobDraft.workType

        if session.jobDraft.workType == .flexible {
            job.targetWeeklyCount = session.jobDraft.targetWeeklyCount
            job.expectedDailyHours = session.jobDraft.expectedDailyHours

            appendInitialAISchedulesIfNeeded(
                to: job,
                session: session
            )

            return job
        }

        job.targetWeeklyCount = nil
        job.expectedDailyHours = nil

        replaceRegularSchedules(
            for: job,
            session: session,
            context: context
        )

        appendInitialAISchedulesIfNeeded(
            to: job,
            session: session
        )

        return job
    }

    @MainActor
    func replaceRegularSchedules(
        for job: Workplace,
        session: JobEditingSession,
        context: ModelContext
    ) {
        let existingSchedules = job.regularSchedules
        job.regularSchedules.removeAll()

        for schedule in existingSchedules where schedule.modelContext != nil {
            context.delete(schedule)
        }

        let orderedSchedules = session.jobDraft.regularSchedules.sorted { left, right in
            let leftIndex = days.firstIndex(of: left.dayOfWeek) ?? 0
            let rightIndex = days.firstIndex(of: right.dayOfWeek) ?? 0
            return leftIndex < rightIndex
        }

        for draft in orderedSchedules {
            let schedule = RegularSchedule(
                dayOfWeek: draft.dayOfWeek,
                startTime: draft.startTime,
                endTime: draft.endTime,
                breakTime: draft.breakTime
            )

            schedule.workplace = job
            job.regularSchedules.append(schedule)

            if job.modelContext != nil {
                context.insert(schedule)
            }
        }

        job.defaultDays = orderedSchedules.map(\.dayOfWeek).joined(separator: ",")

        if let firstSchedule = orderedSchedules.first {
            job.defaultStartTime = firstSchedule.startTime
            job.defaultEndTime = firstSchedule.endTime
        }
    }

    @MainActor
    func appendInitialAISchedulesIfNeeded(
        to job: Workplace,
        session: JobEditingSession
    ) {
        guard session.editingJob == nil else { return }

        let batchID = UUID().uuidString

        for draft in session.scheduleImportDraft.schedules where draft.changeState != .deleted {
            let schedule = workScheduleFactory.make(
                from: draft,
                aiImportBatchID: batchID
            )
            schedule.workplace = job

            job.workSchedules.append(schedule)
        }
    }
}
