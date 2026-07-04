import XCTest
@testable import AlbaTime

@MainActor
final class WorkPlaceDataFlowTests: XCTestCase {
    func testSaveFixedWorkPlaceUsesWriterBoundaryAndPreservesScheduleOrdering() throws {
        let writer = SpyWorkPlacePersistenceWriter()
        let useCase = SaveWorkPlaceUseCase(writer: writer)
        let session = WorkPlaceEditingSession(type: .fixed)
        let mondayStart = Date.makeTime(9, 0)
        let mondayEnd = Date.makeTime(18, 0)
        let wednesdayStart = Date.makeTime(14, 0)
        let wednesdayEnd = Date.makeTime(20, 0)

        session.workPlaceDraft.name = "GS25"
        session.workPlaceDraft.hourlyWage = 11_000
        session.workPlaceDraft.defaultRestTime = 60
        session.workPlaceDraft.regularSchedules = [
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
            .workPlaceDraft(
                editingWorkPlaceID: nil,
                draft: session.workPlaceDraft,
                scheduleImportDraft: session.scheduleImportDraft,
                initialDefaultRestTime: nil
            )
        )

        let request = try XCTUnwrap(writer.savedWorkPlaceDraftRequests.first)
        XCTAssertNil(request.editingWorkPlaceID)
        XCTAssertEqual(request.draft.name, "GS25")
        XCTAssertEqual(request.draft.hourlyWage, 11_000)
        XCTAssertEqual(request.orderedRegularSchedules.map(\.dayOfWeek), ["월", "수"])
        XCTAssertEqual(request.orderedRegularSchedules.first?.startTime, mondayStart)
        XCTAssertEqual(request.orderedRegularSchedules.first?.endTime, mondayEnd)
    }

    func testSaveFlexibleWorkPlaceCreatesFlexiblePersistenceRequest() throws {
        let existingWorkPlace = WorkPlace(
            name: "Cafe",
            hourlyWage: 10_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .fixed
        )
        let writer = SpyWorkPlacePersistenceWriter()
        let useCase = SaveWorkPlaceUseCase(writer: writer)
        let session = WorkPlaceEditingSession(
            seed: WorkPlaceEditingSeedFactory.make(from: existingWorkPlace),
            editingWorkPlaceID: existingWorkPlace.id
        )
        session.workPlaceDraft.workType = .flexible
        session.workPlaceDraft.targetWeeklyCount = 4
        session.workPlaceDraft.expectedDailyHours = 6.5

        try useCase.execute(
            .workPlaceDraft(
                editingWorkPlaceID: existingWorkPlace.id,
                draft: session.workPlaceDraft,
                scheduleImportDraft: session.scheduleImportDraft,
                initialDefaultRestTime: 30
            )
        )

        let request = try XCTUnwrap(writer.savedWorkPlaceDraftRequests.first)
        XCTAssertEqual(request.editingWorkPlaceID, existingWorkPlace.id)
        XCTAssertEqual(request.draft.workType, .flexible)
        XCTAssertEqual(request.draft.targetWeeklyCount, 4)
        XCTAssertEqual(request.draft.expectedDailyHours, 6.5)
        XCTAssertTrue(request.orderedRegularSchedules.isEmpty)
        XCTAssertEqual(request.initialDefaultRestTime, 30)
    }

    func testWorkPlaceEditingSeedFactoryBuildsEditingSeedFromWorkPlace() {
        let workPlace = WorkPlace(
            name: "Cafe",
            hourlyWage: 10_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        workPlace.defaultRestTime = 45
        workPlace.defaultMemo = "마감 정산 확인"
        workPlace.targetWeeklyCount = 3
        workPlace.expectedDailyHours = 5.5

        let seed = WorkPlaceEditingSeedFactory.make(from: workPlace)

        XCTAssertEqual(seed.id, workPlace.id)
        XCTAssertEqual(seed.workPlaceDraft.name, "Cafe")
        XCTAssertEqual(seed.workPlaceDraft.hourlyWage, 10_000)
        XCTAssertEqual(seed.workPlaceDraft.workType, .flexible)
        XCTAssertEqual(seed.workPlaceDraft.targetWeeklyCount, 3)
        XCTAssertEqual(seed.workPlaceDraft.expectedDailyHours, 5.5)
        XCTAssertEqual(seed.scheduleImportDraft.presetDrafts.count, 0)
        XCTAssertEqual(seed.savedAIScheduleItems.count, 0)
        XCTAssertEqual(seed.initialDefaultRestTime, 45)
    }

    func testWorkPlaceListViewStateMapperBuildsFixedScheduleSummaryInDayOrder() {
        let workPlace = WorkPlace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .fixed
        )
        workPlace.regularSchedules = [
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

        let item = WorkPlaceListViewStateMapper.makeItem(from: workPlace)

        XCTAssertEqual(item.card.id, workPlace.id)
        XCTAssertEqual(item.card.name, "Store")
        XCTAssertEqual(item.card.scheduleSummary, "월: 09:00 ~ 18:00\n수: 14:00 ~ 20:00")
        XCTAssertEqual(item.detail.fixedDaysText, "월/수")
        XCTAssertEqual(item.editingSeed.id, workPlace.id)
    }

    func testWorkPlaceListViewStateMapperBuildsFlexibleSummaryAndMemo() {
        let workPlace = WorkPlace(
            name: "Cafe",
            hourlyWage: 11_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        workPlace.targetWeeklyCount = 4
        workPlace.expectedDailyHours = 6.5
        workPlace.defaultRestTime = 30
        workPlace.defaultMemo = "피크타임 지원"

        let item = WorkPlaceListViewStateMapper.makeItem(from: workPlace)

        XCTAssertEqual(item.card.scheduleSummary, "주 4회 / 일 평균 6.5시간")
        XCTAssertEqual(item.detail.memo, "피크타임 지원")
        XCTAssertEqual(item.detail.targetWeeklyCount, 4)
        XCTAssertEqual(item.detail.expectedDailyHours, 6.5)
        XCTAssertEqual(item.detail.defaultRestTime, 30)
    }

    func testAddWorkPlaceViewModelSavesThroughWorkPlaceSavingProtocol() {
        let saving = SpyWorkPlaceSaving()
        let viewModel = AddWorkPlaceViewModel(type: .fixed, workPlaceSaving: saving)

        XCTAssertTrue(viewModel.save())
        XCTAssertEqual(saving.receivedCommands.count, 1)
        XCTAssertFalse(viewModel.showAlert)
    }

    func testAddWorkPlaceViewModelShowsAlertWhenWorkPlaceSavingProtocolThrows() {
        let saving = SpyWorkPlaceSaving(error: SaveWorkPlaceError.invalidWage)
        let viewModel = AddWorkPlaceViewModel(type: .fixed, workPlaceSaving: saving)

        XCTAssertFalse(viewModel.save())
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, SaveWorkPlaceError.invalidWage.localizedDescription)
    }

    func testWorkPlaceListViewModelUsesCommandProtocols() {
        let workPlace = WorkPlace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "월",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0)
        )
        let delete = SpyWorkPlaceDeleting()
        let alarm = SpyWorkPlaceAlarmToggling()
        let pin = SpyWorkPlacePinToggling()
        let memo = SpyWorkPlaceMemoUpdating()
        let viewModel = WorkPlaceListViewModel(
            workPlaceDeleting: delete,
            alarmToggling: alarm,
            pinToggling: pin,
            memoUpdating: memo
        )

        viewModel.delete(workPlaceID: workPlace.id)
        XCTAssertTrue(viewModel.toggleAlarm(workPlaceID: workPlace.id))
        XCTAssertTrue(viewModel.togglePin(workPlaceID: workPlace.id))

        XCTAssertEqual(delete.deletedWorkPlaceIDs, [workPlace.id])
        XCTAssertEqual(alarm.toggledWorkPlaceIDs, [workPlace.id])
        XCTAssertEqual(pin.toggledWorkPlaceIDs, [workPlace.id])
    }

    func testScheduleImportViewModelSavesExistingWorkPlaceThroughScheduleSavingProtocol() {
        let workPlace = WorkPlace(
            name: "Store",
            hourlyWage: 12_000,
            defaultDays: "",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            workType: .flexible
        )
        let session = WorkPlaceEditingSession(
            seed: WorkPlaceEditingSeedFactory.make(from: workPlace),
            editingWorkPlaceID: workPlace.id
        )
        let viewModel = ScheduleImportViewModel(
            session: session,
            analyzeScheduleImage: DefaultScheduleAnalysis.makeUseCase()
        )
        let saving = SpyScheduleSaving()

        XCTAssertTrue(viewModel.saveResultSchedules(using: saving))
        XCTAssertEqual(saving.receivedCommands.count, 1)

        guard case .editDraft(let receivedWorkPlaceID, let draft)? = saving.receivedCommands.first else {
            XCTFail("Expected edit draft command")
            return
        }
        XCTAssertEqual(receivedWorkPlaceID, workPlace.id)
        XCTAssertEqual(draft.state, .existingWorkPlaceAIImport)
    }

    func testScheduleImportViewModelKeepsNewWorkPlacePanelDraftInSessionWithoutPersistence() throws {
        let session = WorkPlaceEditingSession(type: .flexible)
        let viewModel = ScheduleImportViewModel(
            session: session,
            analyzeScheduleImage: DefaultScheduleAnalysis.makeUseCase()
        )
        let saving = SpyScheduleSaving()
        let kept = makeScheduleDraftItem(changeState: .inserted)
        let deleted = makeScheduleDraftItem(changeState: .deleted)
        let draft = ScheduleEditDraft(
            state: .newWorkPlaceInitialSchedules,
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
private final class SpyWorkPlacePersistenceWriter: WorkPlacePersistenceWriting {
    var savedWorkPlaceDraftRequests: [PersistWorkPlaceDraftRequest] = []
    var savedScheduleDraftRequests: [ScheduleDraftPersistenceRequest] = []
    var deletedWorkPlaceIDs: [UUID] = []
    var alarmToggledIDs: [UUID] = []
    var pinToggledIDs: [UUID] = []
    var memoUpdates: [(id: UUID, memo: String)] = []

    func saveWorkPlaceDraft(_ request: PersistWorkPlaceDraftRequest) throws {
        savedWorkPlaceDraftRequests.append(request)
    }

    func saveScheduleDraft(_ request: ScheduleDraftPersistenceRequest) throws {
        savedScheduleDraftRequests.append(request)
    }

    func deleteWorkPlace(id: UUID) {
        deletedWorkPlaceIDs.append(id)
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
private final class SpyWorkPlaceSaving: WorkPlaceSaving {
    var receivedCommands: [SaveWorkPlaceCommand] = []
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func execute(_ command: SaveWorkPlaceCommand) throws {
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
private final class SpyWorkPlaceDeleting: WorkPlaceDeleting {
    var deletedWorkPlaceIDs: [UUID] = []

    func execute(workPlaceID: UUID) throws {
        deletedWorkPlaceIDs.append(workPlaceID)
    }
}

@MainActor
private final class SpyWorkPlaceAlarmToggling: WorkPlaceAlarmToggling {
    var toggledWorkPlaceIDs: [UUID] = []

    func execute(workPlaceID: UUID) throws {
        toggledWorkPlaceIDs.append(workPlaceID)
    }
}

@MainActor
private final class SpyWorkPlacePinToggling: WorkPlacePinToggling {
    var toggledWorkPlaceIDs: [UUID] = []

    func execute(workPlaceID: UUID) throws {
        toggledWorkPlaceIDs.append(workPlaceID)
    }
}

@MainActor
private final class SpyWorkPlaceMemoUpdating: WorkPlaceMemoUpdating {
    var memoUpdates: [(id: UUID, memo: String)] = []

    func execute(workPlaceID: UUID, memo: String) throws {
        memoUpdates.append((workPlaceID, memo))
    }
}
