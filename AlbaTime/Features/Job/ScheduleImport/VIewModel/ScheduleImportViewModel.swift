//
//  ScheduleImportViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import Vision
import SwiftData
import PhotosUI

// 뷰 상태 처리
enum ScheduleImportPhase {
    case idle
    case loading
    case result
}

@MainActor
class ScheduleImportViewModel: ObservableObject {

    // processSelectedPhoto에서 사용
    @Published var selectedImage: UIImage? // ScheduleImportResultList에 사진 보여주기
    @Published var phase: ScheduleImportPhase = .idle

    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""

    // preset 연관 변수
    @Published var isAddingPreset: Bool = false
    @Published var newPresetLabel: String = "" // 프리셋 이름
    @Published var newPresetStart: Date = Date.makeTime(9, 0)
    @Published var newPresetEnd: Date = Date.makeTime(18, 0)

    var session: JobEditingSession

    // UseCase
    private let analyzeScheduleImage = AnalyzeScheduleImage()
    private let saveScheduleUseCase = SaveScheduleUseCase()

    init(session: JobEditingSession) {
        self.session = session
    }

    var hasSavedAISchedules: Bool {
        guard let job = session.editingJob else { return false }
        return job.workSchedules.contains { $0.isFromAIImport }
    }

    var panelDefaultBreakTime: Int {
        session.jobDraft.defaultRestTime
    }

    var presetDrafts: [TimePresetDraft] {
        session.scheduleImportDraft.presetDrafts
    }

    var hasScheduleDrafts: Bool {
        !session.scheduleImportDraft.schedules.isEmpty
    }

    func shouldShowSchedulePanel(manualFocusToken: Int) -> Bool {
        hasSavedAISchedules || manualFocusToken > 0
    }

    func makeSchedulePanelDraft(targetWeekStart: Date? = nil) -> ScheduleEditDraft {
        if let job = session.editingJob {
            return .fromSavedAISchedules(
                job: job,
                targetWeekStart: targetWeekStart
            )
        }

        return session.scheduleImportDraft.makeEditDraft(
            mode: .newJobInitialSchedules,
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
                self.analyzeImage(targetName: targetName)
            } else {
                self.errorMessage = "이미지 데이터를 불러올 수 없습니다."
                self.showAlert = true
            }
        } catch {
            print("사진 로드 에러: \(error)")
            self.errorMessage = "사진 로드 중 오류 발생.\n권한을 확인해주세요."
            self.showAlert = true
        }
    }

    // processSelectedPhoto에서 사용
    func analyzeImage(targetName: String = "") {
        guard let image = selectedImage else { return }

//        guard session.editingJob != nil else {
//            errorMessage = "근무지 정보가 없습니다."
//            showAlert = true
//            return
//        }

        phase = .loading
        session.scheduleImportDraft.schedules = []

        let presetModels = session.scheduleImportDraft.presetDrafts.map {
            WorkTimePreset(
                label: $0.label,
                startTime: $0.startTime,
                endTime: $0.endTime
            )
        }

        Task {
            do {
                let schedules = try await analyzeScheduleImage.execute(
                    image: image,
                    targetName: targetName,
                    presets: presetModels
                )

                self.session.scheduleImportDraft.schedules = schedules.map {
                    ScheduleDraftItem(
                        parsedSchedule: $0,
                        breakTime: self.session.jobDraft.defaultRestTime,
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

    // SceduleImportResultList에서 ai로 인식한 스케줄 외 추가시에 호출
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
            breakTime: session.jobDraft.defaultRestTime,
            memo: nil,
            source: .manual
        )

        // 추가
        session.scheduleImportDraft.schedules.append(newSchedule)

        // 날짜순 정렬 (추가된 게 중간에 끼어들 수도 있으므로)
        session.scheduleImportDraft.schedules.sort { $0.date < $1.date }
    }

    // ScheduleImportBottomButtons에서 저장버튼 누를시에 호출 -> ai 인식 결과 저장
    func saveResultSchedules(context: ModelContext, targetWeekStart: Date? = nil) -> Bool {
        guard session.editingJob != nil else { return true }

        return saveToWorkplace(
            context: context,
            targetWeekStart: targetWeekStart
        )
    }

    func saveToWorkplace(context: ModelContext, targetWeekStart: Date? = nil) -> Bool {
        do {
            try saveScheduleUseCase.execute(
                .editDraft(
                    job: session.editingJob,
                    draft: session.scheduleImportDraft.makeEditDraft(
                        mode: .existingJobAIImport,
                        targetWeekStart: targetWeekStart
                    )
                ),
                context: context
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
            return false
        }
    }

    func saveSchedulePanelDraft(
        _ draft: ScheduleEditDraft,
        context: ModelContext
    ) throws {
        if let job = session.editingJob {
            try saveScheduleUseCase.execute(
                .editDraft(job: job, draft: draft),
                context: context
            )
            return
        }

        session.scheduleImportDraft.schedules = draft.items
            .filter { $0.changeState != .deleted }
    }

    // MARK: preset 연관 메서드
    // ScheduleImportPresetGroup에서 사용

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
