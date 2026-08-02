//
//  ScheduleImportViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import PhotosUI

// 뷰 상태 처리
enum ScheduleImportPhase {
    case idle
    case loading
    case result
}

@MainActor
class ScheduleImportViewModel: ObservableObject {

    @Published var selectedImage: UIImage? // ScheduleImportResultList에 사진 보여주기
    @Published var phase: ScheduleImportPhase = .idle

    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""

    // preset 연관 변수
    @Published var isAddingPreset: Bool = false
    @Published var newPresetLabel: String = "" // 프리셋 이름
    @Published var newPresetStart: Date = Date.makeTime(9, 0)
    @Published var newPresetEnd: Date = Date.makeTime(18, 0)

    var session: WorkPlaceEditingSession

    // UseCase
    private let analyzeScheduleImage: any ScheduleImageAnalyzing
    private var selectedImageData: Data?

    private let analyticsTracker: any AnalyticsTracking

    init(
        session: WorkPlaceEditingSession,
        analyzeScheduleImage: any ScheduleImageAnalyzing,
        analyticsTracker: any AnalyticsTracking
    ) {
        self.session = session
        self.analyzeScheduleImage = analyzeScheduleImage
        self.analyticsTracker = analyticsTracker
    }

    var hasSavedSchedules: Bool {
        !session.savedScheduleItems.isEmpty
    }

    var panelDefaultBreakTime: Int {
        session.workPlaceDraft.defaultRestTime
    }

    var presetDrafts: [TimePresetDraft] {
        session.scheduleImportDraft.presetDrafts
    }

    var hasScheduleDrafts: Bool {
        !session.scheduleImportDraft.schedules.isEmpty
    }

    func shouldShowSchedulePanel(manualFocusToken: Int) -> Bool {
        hasSavedSchedules || manualFocusToken > 0
    }

    func enterManualInputMode() {
        selectedImage = nil
        phase = .idle
    }

    func makeSchedulePanelDraft(targetWeekStart: Date? = nil) -> ScheduleEditDraft {
        if hasSavedSchedules {
            return ScheduleEditDraft(
                state: .existingSavedScheduleEdit,
                targetWeekStart: targetWeekStart,
                items: session.savedScheduleItems
            )
        }

        return session.scheduleImportDraft.makeEditDraft(
            state: .newWorkPlaceInitialSchedules,
            targetWeekStart: targetWeekStart
        )
    }

    // 뷰에서 .onChange로 뷰 상태 변경시 호출
    func processSelectedPhoto(item: PhotosPickerItem?, targetName: String) async {
        guard let item else { return }

        phase = .loading

        do {
            // Transferable 프로토콜을 이용해 데이터 로드
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {

                self.selectedImage = image
                self.selectedImageData = data
                self.analyzeImage(targetName: targetName)
            } else {
                self.errorMessage = "이미지 데이터를 불러올 수 없어요."
                self.showAlert = true
            }
        } catch {
            print("사진 로드 에러: \(error)")
            self.errorMessage = "사진 로드 중 오류 발생.\n권한을 확인해주세요."
            self.showAlert = true
        }
    }

    func analyzeImage(targetName: String = "") {
        guard let imageData = selectedImageData else { return }

        phase = .loading
        session.scheduleImportDraft.schedules = []

        Task {
            do {
                let schedules = try await analyzeScheduleImage.execute(
                    imageData: imageData,
                    targetName: targetName,
                    presets: session.scheduleImportDraft.presetDrafts
                )

                self.session.scheduleImportDraft.schedules = schedules.map {
                    ScheduleDraftItem(
                        parsedSchedule: $0,
                        breakTime: self.session.workPlaceDraft.defaultRestTime,
                        source: .aiImport
                    )
                }

                if schedules.isEmpty {
                    self.phase = .idle
                    self.errorMessage = targetName.isEmpty
                        ? "스케줄 형식을 찾지 못했어요."
                        : "'\(targetName)'님의 스케줄을 찾지 못했어요.\n이름이 정확한지 확인해주세요."
                    self.showAlert = true
                } else {
                    self.phase = .result
                }
            } catch {
                self.phase = .idle
                self.errorMessage = "분석 중 오류가 발생했어요: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }

    // ScheduleImportResultList에서 AI로 인식한 스케줄 외 추가시에 호출
    func addNewSchedule(targetWeekStart: Date? = nil) {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: targetWeekStart ?? Date())
        let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        var targetDate = weekStart

        // 날짜순 정렬
        let schedulesInWeek = session.scheduleImportDraft.schedules
            .filter { $0.date >= weekStart && $0.date < weekEndExclusive }
            .sorted(by: { $0.date < $1.date })

        // UX 관점 이미 인식된 날짜 다음 날로 자동 생성 ex) 월 화 있으면 추가 버튼 누르면 수요일 자동생성
        if let lastSchedule = schedulesInWeek.last {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastSchedule.date) {
                targetDate = nextDay
            }
        }

        // 주 넘어가면 마지막날로 보정하기
        if targetDate >= weekEndExclusive {
            targetDate = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        }

        // 2. 기본 시간: 09:00 ~ 18:00 // guard let 구문으로 강제언래핑 제거
        guard let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate),
              let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate)
        else {
            errorMessage = "기본 시간 생성에 실패했어요."
            showAlert = true
            return
        }

        let newSchedule = ScheduleDraftItem(
            id: UUID(),
            date: targetDate,
            startTime: start,
            endTime: end,
            breakTime: session.workPlaceDraft.defaultRestTime,
            memo: nil,
            source: .manual
        )

        // 추가
        session.scheduleImportDraft.schedules.append(newSchedule)

        // 날짜순 정렬 (추가된 게 중간에 끼어들 수도 있으므로)
        session.scheduleImportDraft.schedules.sort { $0.date < $1.date }
    }

    // ScheduleImportBottomButtons에서 저장버튼 누를시에 호출 -> ai 인식 결과 저장
    func saveResultSchedules(
        using scheduleSaving: any ScheduleSaving,
        targetWeekStart: Date? = nil
    ) -> Bool {
        // 신규 근무지는 이 화면에서 직접 저장하지 않고 AddWorkPlace 화면으로
        // 초안을 넘기므로, 여기서 선택한 기준 주에 맞춰 날짜를 먼저 확정합니다.
        if session.editingWorkPlaceID == nil {
            mapDraftSchedules(to: targetWeekStart)
            return true
        }

        return saveToWorkPlace(
            using: scheduleSaving,
            targetWeekStart: targetWeekStart
        )
    }

    private func mapDraftSchedules(to targetWeekStart: Date?) {
        guard let targetWeekStart else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: targetWeekStart)

        session.scheduleImportDraft.schedules = session.scheduleImportDraft.schedules.map { item in
            let weekday = calendar.component(.weekday, from: item.date)
            let mondayBasedOffset = (weekday + 5) % 7
            let mappedDate = calendar.date(
                byAdding: .day,
                value: mondayBasedOffset,
                to: start
            ) ?? item.date

            let timeComponents = calendar.dateComponents([.hour, .minute], from: item.startTime)
            let mappedStart = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: mappedDate
            ) ?? item.startTime

            var mappedEnd = calendar.date(
                bySettingHour: calendar.component(.hour, from: item.endTime),
                minute: calendar.component(.minute, from: item.endTime),
                second: 0,
                of: mappedDate
            ) ?? item.endTime

            if mappedEnd < mappedStart {
                mappedEnd = calendar.date(byAdding: .day, value: 1, to: mappedEnd) ?? mappedEnd
            }

            var mappedItem = item
            mappedItem.date = mappedDate
            mappedItem.startTime = mappedStart
            mappedItem.endTime = mappedEnd
            return mappedItem
        }
    }

    func saveToWorkPlace(
        using scheduleSaving: any ScheduleSaving,
        targetWeekStart: Date? = nil
    ) -> Bool {
        do {
            let draft = session.scheduleImportDraft.makeEditDraft(
                state: .existingWorkPlaceAIImport,
                targetWeekStart: targetWeekStart
            )

            try scheduleSaving.execute(
                .editDraft(
                    workPlaceID: session.editingWorkPlaceID,
                    draft: draft
                )
            )

            trackSavedScheduleEvents(from: draft.items)

            return true
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
            return false
        }
    }

    func saveSchedulePanelDraft(
        _ draft: ScheduleEditDraft,
        using scheduleSaving: any ScheduleSaving
    ) throws {
        if let editingWorkPlaceID = session.editingWorkPlaceID {
            try scheduleSaving.execute(.editDraft(workPlaceID: editingWorkPlaceID, draft: draft))
            trackSavedScheduleEvents(from: draft.items)
            return
        }

        session.scheduleImportDraft.schedules = draft.items
            .filter { $0.changeState != .deleted }
    }

    private func trackSavedScheduleEvents(from items: [ScheduleEditItem]) {
        let changedItems = items.filter { $0.changeState != .clean }

        if changedItems.contains(where: { $0.source == .aiImport }) {
            analyticsTracker.track(.aiScheduleSaved)
        }

        if changedItems.contains(where: { $0.source == .manual }) {
            analyticsTracker.track(.manualScheduleSaved)
        }
    }

    // MARK: preset 연관 메서드

    func addNewPreset() {
        guard !newPresetLabel.isEmpty else {return}

        let preset = TimePresetDraft(
            id: UUID(),
            label: newPresetLabel,
            startTime: newPresetStart,
            endTime: newPresetEnd
        )

        session.scheduleImportDraft.presetDrafts.append(preset)
        newPresetLabel = "" // 입력창 초기화 다음 프리셋 추가를 위해
        isAddingPreset = false
    }

    func deletePreset(_ preset: TimePresetDraft) {
        guard let index = session.scheduleImportDraft.presetDrafts.firstIndex(where: { $0.id == preset.id }) else { return }
        session.scheduleImportDraft.presetDrafts.remove(at: index)
    }
}
