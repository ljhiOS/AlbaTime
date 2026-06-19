import XCTest
@testable import AlbaTime

@MainActor
final class JobDataFlowTests: XCTestCase {
    func testSaveFixedJobUsesWriterBoundaryAndPreservesScheduleOrdering() throws {
        let writer = SpyJobPersistenceWriter()
        let useCase = SaveJobUseCase(writer: writer)
        let session = JobEditingSession(type: .fixed)
        let mondayStart = Date.makeTime(9, 0)
        let mondayEnd = Date.makeTime(18, 0)
        let wednesdayStart = Date.makeTime(14, 0)
        let wednesdayEnd = Date.makeTime(20, 0)

        session.jobDraft.name = "GS25"
        session.jobDraft.hourlyWage = 11_000
        session.jobDraft.defaultRestTime = 60
        session.jobDraft.regularSchedules = [
            RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: "수",
                startTime: wednesdayStart,
                endTime: wednesdayEnd,
                breakTime: 60
            ),
            RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: "월",
                startTime: mondayStart,
                endTime: mondayEnd,
                breakTime: 60
            )
        ]

        try useCase.execute(
            .jobDraft(
                editingJobID: nil,
                draft: session.jobDraft,
                scheduleImportDraft: session.scheduleImportDraft,
                initialDefaultRestTime: nil
            )
        )

        let request = try XCTUnwrap(writer.savedJobDraftRequests.first)
        XCTAssertNil(request.editingJobID)
        XCTAssertEqual(request.draft.name, "GS25")
        XCTAssertEqual(request.draft.hourlyWage, 11_000)
        XCTAssertEqual(request.orderedRegularSchedules.map(\.dayOfWeek), ["월", "수"])
        XCTAssertEqual(request.orderedRegularSchedules.first?.startTime, mondayStart)
        XCTAssertEqual(request.orderedRegularSchedules.first?.endTime, mondayEnd)
    }

    func testSaveFlexibleJobCreatesFlexiblePersistenceRequest() throws {
        let existingJob = Workplace(
            name: "Cafe",
            hourlyWage: 10_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .fixed
        )
        let writer = SpyJobPersistenceWriter()
        let useCase = SaveJobUseCase(writer: writer)
        let session = JobEditingSession(
            seed: JobEditingSeedFactory.make(from: existingJob),
            editingJobID: existingJob.id
        )
        session.jobDraft.workType = .flexible
        session.jobDraft.targetWeeklyCount = 4
        session.jobDraft.expectedDailyHours = 6.5

        try useCase.execute(
            .jobDraft(
                editingJobID: existingJob.id,
                draft: session.jobDraft,
                scheduleImportDraft: session.scheduleImportDraft,
                initialDefaultRestTime: 30
            )
        )

        let request = try XCTUnwrap(writer.savedJobDraftRequests.first)
        XCTAssertEqual(request.editingJobID, existingJob.id)
        XCTAssertEqual(request.draft.workType, .flexible)
        XCTAssertEqual(request.draft.targetWeeklyCount, 4)
        XCTAssertEqual(request.draft.expectedDailyHours, 6.5)
        XCTAssertTrue(request.orderedRegularSchedules.isEmpty)
        XCTAssertEqual(request.initialDefaultRestTime, 30)
    }

    func testJobEditingSeedFactoryBuildsEditingSeedFromWorkplace() {
        let job = Workplace(
            name: "Cafe",
            hourlyWage: 10_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        job.defaultRestTime = 45
        job.defaultMemo = "마감 정산 확인"
        job.targetWeeklyCount = 3
        job.expectedDailyHours = 5.5

        let seed = JobEditingSeedFactory.make(from: job)

        XCTAssertEqual(seed.id, job.id)
        XCTAssertEqual(seed.jobDraft.name, "Cafe")
        XCTAssertEqual(seed.jobDraft.hourlyWage, 10_000)
        XCTAssertEqual(seed.jobDraft.workType, .flexible)
        XCTAssertEqual(seed.jobDraft.targetWeeklyCount, 3)
        XCTAssertEqual(seed.jobDraft.expectedDailyHours, 5.5)
        XCTAssertEqual(seed.scheduleImportDraft.presetDrafts.count, 0)
        XCTAssertEqual(seed.savedAIScheduleItems.count, 0)
        XCTAssertEqual(seed.initialDefaultRestTime, 45)
    }

    func testJobListViewStateMapperBuildsFixedScheduleSummaryInDayOrder() {
        let job = Workplace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .fixed
        )
        job.regularSchedules = [
            RegularSchedule(
                dayOfWeek: "수",
                startTime: Date.makeTime(14, 0),
                endTime: Date.makeTime(20, 0),
                breakTime: 30
            ),
            RegularSchedule(
                dayOfWeek: "월",
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: 60
            )
        ]

        let item = JobListViewStateMapper.makeItem(from: job)

        XCTAssertEqual(item.card.id, job.id)
        XCTAssertEqual(item.card.name, "Store")
        XCTAssertEqual(item.card.scheduleSummary, "월: 09:00 ~ 18:00\n수: 14:00 ~ 20:00")
        XCTAssertEqual(item.detail.fixedDaysText, "월/수")
        XCTAssertEqual(item.editingSeed.id, job.id)
    }

    func testJobListViewStateMapperBuildsFlexibleSummaryAndMemo() {
        let job = Workplace(
            name: "Cafe",
            hourlyWage: 11_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        job.targetWeeklyCount = 4
        job.expectedDailyHours = 6.5
        job.defaultRestTime = 30
        job.defaultMemo = "피크타임 지원"

        let item = JobListViewStateMapper.makeItem(from: job)

        XCTAssertEqual(item.card.scheduleSummary, "주 4회 / 일 평균 6.5시간")
        XCTAssertEqual(item.detail.memo, "피크타임 지원")
        XCTAssertEqual(item.detail.targetWeeklyCount, 4)
        XCTAssertEqual(item.detail.expectedDailyHours, 6.5)
        XCTAssertEqual(item.detail.defaultRestTime, 30)
    }

    func testAddJobViewModelSavesThroughJobSavingProtocol() {
        let saving = SpyJobSaving()
        let viewModel = AddJobViewModel(type: .fixed, jobSaving: saving)

        XCTAssertTrue(viewModel.save())
        XCTAssertEqual(saving.receivedCommands.count, 1)
        XCTAssertFalse(viewModel.showAlert)
    }

    func testAddJobViewModelShowsAlertWhenJobSavingProtocolThrows() {
        let saving = SpyJobSaving(error: SaveJobError.invalidWage)
        let viewModel = AddJobViewModel(type: .fixed, jobSaving: saving)

        XCTAssertFalse(viewModel.save())
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, SaveJobError.invalidWage.localizedDescription)
    }

    func testJobListViewModelUsesCommandProtocols() {
        let job = Workplace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0)
        )
        let delete = SpyWorkplaceDeleting()
        let alarm = SpyWorkplaceAlarmToggling()
        let pin = SpyWorkplacePinToggling()
        let memo = SpyWorkplaceMemoUpdating()
        let viewModel = JobListViewModel(
            workplaceDeleting: delete,
            alarmToggling: alarm,
            pinToggling: pin,
            memoUpdating: memo
        )

        viewModel.delete(workplaceID: job.id)
        XCTAssertTrue(viewModel.toggleAlarm(workplaceID: job.id))
        XCTAssertTrue(viewModel.togglePin(workplaceID: job.id))

        XCTAssertEqual(delete.deletedWorkplaceIDs, [job.id])
        XCTAssertEqual(alarm.toggledWorkplaceIDs, [job.id])
        XCTAssertEqual(pin.toggledWorkplaceIDs, [job.id])
    }

    func testScheduleImportViewModelSavesExistingJobThroughScheduleSavingProtocol() {
        let job = Workplace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        let session = JobEditingSession(
            seed: JobEditingSeedFactory.make(from: job),
            editingJobID: job.id
        )
        let viewModel = ScheduleImportViewModel(session: session)
        let saving = SpyScheduleSaving()

        XCTAssertTrue(viewModel.saveResultSchedules(using: saving))
        XCTAssertEqual(saving.receivedCommands.count, 1)

        guard case .editDraft(let receivedJobID, let draft)? = saving.receivedCommands.first else {
            XCTFail("Expected edit draft command")
            return
        }
        XCTAssertEqual(receivedJobID, job.id)
        XCTAssertEqual(draft.state, .existingJobAIImport)
    }

    func testScheduleImportViewModelKeepsNewJobPanelDraftInSessionWithoutPersistence() throws {
        let session = JobEditingSession(type: .flexible)
        let viewModel = ScheduleImportViewModel(session: session)
        let saving = SpyScheduleSaving()
        let kept = makeScheduleDraftItem(changeState: .inserted)
        let deleted = makeScheduleDraftItem(changeState: .deleted)
        let draft = ScheduleEditDraft(
            state: .newJobInitialSchedules,
            targetWeekStart: nil,
            items: [kept, deleted]
        )

        try viewModel.saveSchedulePanelDraft(draft, using: saving)

        XCTAssertTrue(saving.receivedCommands.isEmpty)
        XCTAssertEqual(session.scheduleImportDraft.schedules.map(\.id), [kept.id])
    }

    private func makeScheduleDraftItem(
        changeState: ScheduleDraftChangeState
    ) -> ScheduleDraftItem {
        ScheduleDraftItem(
            id: UUID(),
            date: Date(),
            startTime: Date.makeTime(9, 0),
            endTime: Date.makeTime(18, 0),
            breakTime: 30,
            memo: nil,
            source: .manual,
            changeState: changeState
        )
    }
}

@MainActor
private final class SpyJobPersistenceWriter: JobPersistenceWriting {
    var savedJobDraftRequests: [JobDraftPersistenceRequest] = []
    var savedScheduleDraftRequests: [ScheduleDraftPersistenceRequest] = []
    var deletedWorkplaceIDs: [UUID] = []
    var alarmToggledIDs: [UUID] = []
    var pinToggledIDs: [UUID] = []
    var memoUpdates: [(id: UUID, memo: String)] = []

    func saveJobDraft(_ request: JobDraftPersistenceRequest) throws {
        savedJobDraftRequests.append(request)
    }

    func saveScheduleDraft(_ request: ScheduleDraftPersistenceRequest) throws {
        savedScheduleDraftRequests.append(request)
    }

    func deleteWorkplace(id: UUID) {
        deletedWorkplaceIDs.append(id)
    }

    func toggleAlarm(id: UUID) {
        alarmToggledIDs.append(id)
    }

    func togglePin(id: UUID) {
        pinToggledIDs.append(id)
    }

    func updateMemo(id: UUID, memo: String) {
        memoUpdates.append((id, memo))
    }
}

@MainActor
private final class SpyJobSaving: JobSaving {
    var receivedCommands: [JobSaveCommand] = []
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func execute(_ command: JobSaveCommand) throws {
        receivedCommands.append(command)
        if let error {
            throw error
        }
    }
}

@MainActor
private final class SpyScheduleSaving: ScheduleSaving {
    var receivedCommands: [SaveScheduleCommand] = []

    func execute(_ command: SaveScheduleCommand) throws {
        receivedCommands.append(command)
    }
}

@MainActor
private final class SpyWorkplaceDeleting: WorkplaceDeleting {
    var deletedWorkplaceIDs: [UUID] = []

    func execute(workplaceID: UUID) throws {
        deletedWorkplaceIDs.append(workplaceID)
    }
}

@MainActor
private final class SpyWorkplaceAlarmToggling: WorkplaceAlarmToggling {
    var toggledWorkplaceIDs: [UUID] = []

    func execute(workplaceID: UUID) throws {
        toggledWorkplaceIDs.append(workplaceID)
    }
}

@MainActor
private final class SpyWorkplacePinToggling: WorkplacePinToggling {
    var toggledWorkplaceIDs: [UUID] = []

    func execute(workplaceID: UUID) throws {
        toggledWorkplaceIDs.append(workplaceID)
    }
}

@MainActor
private final class SpyWorkplaceMemoUpdating: WorkplaceMemoUpdating {
    var memoUpdates: [(id: UUID, memo: String)] = []

    func execute(workplaceID: UUID, memo: String) throws {
        memoUpdates.append((workplaceID, memo))
    }
}
