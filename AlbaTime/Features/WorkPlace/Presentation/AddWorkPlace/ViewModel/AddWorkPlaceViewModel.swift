//
//  AddWorkPlaceViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Combine
import Foundation

@MainActor
class AddWorkPlaceViewModel: ObservableObject {
    var session: WorkPlaceEditingSession
    
    @Published var isAIImportPresented: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    private let originalWorkPlaceDraft: WorkPlaceDraft
    
    // 실제 저장 UseCase는 Route/Composition에서 주입됩니다.
    private let workPlaceSaving: any WorkPlaceSaving
    private var hasSavedChanges: Bool = false
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    
    // 신규 생성 모드
    init(type: WorkType, workPlaceSaving: any WorkPlaceSaving) {
        let seed = WorkPlaceEditingSeed.new(type: type)
        self.session = WorkPlaceEditingSession(seed: seed)
        self.originalWorkPlaceDraft = seed.workPlaceDraft
        self.workPlaceSaving = workPlaceSaving
    }
    
    // 수정 모드
    init(editingSeed: WorkPlaceEditingSeed, workPlaceSaving: any WorkPlaceSaving) {
        self.session = WorkPlaceEditingSession(seed: editingSeed, editingWorkPlaceID: editingSeed.id)
        self.originalWorkPlaceDraft = editingSeed.workPlaceDraft
        self.workPlaceSaving = workPlaceSaving
    }
    
    // MARK: - 유효성 검사 및 AI
    // TODO: 저장 검증과 AI 진입 전 기본 검증의 중복 조건 정리 검토
    func validateAndOpenAI() {
        if session.workPlaceDraft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        if session.workPlaceDraft.hourlyWage <= 0 {
            errorMessage = "올바른 시급을 입력해주세요."
            showAlert = true
            return
        }
        isAIImportPresented = true
    }
    
    // MARK: - 요일별 스케줄 로직
    
    func getSchedule(for day: String) -> RegularScheduleDraft? {
        session.workPlaceDraft.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    // MARK: 스케줄 선택 및 취소
    func updateStartTime(for day: String, to newValue: Date) {
        guard let index = session.workPlaceDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.workPlaceDraft.regularSchedules[index].startTime = newValue
    }
    
    func updateEndTime(for day: String, to newValue: Date) {
        guard let index = session.workPlaceDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.workPlaceDraft.regularSchedules[index].endTime = newValue
    }

    func toggleDay(_ day: String) {
        if let index = session.workPlaceDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) {
            session.workPlaceDraft.regularSchedules.remove(at: index)
        } else {
            let newSchedule = RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.workPlaceDraft.defaultRestTime
            )
            session.workPlaceDraft.regularSchedules.append(newSchedule)
        }
    }

    func resetAllDays() {
        let weekdays = ["월", "화", "수", "목", "금"]
        
        session.workPlaceDraft.regularSchedules = weekdays.map { day in
            RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.workPlaceDraft.defaultRestTime
            )
        }
    }
    
    // MARK: 저장
    func save() -> Bool {
        do {
            try workPlaceSaving.execute(
                .workPlaceDraft(
                    editingWorkPlaceID: session.editingWorkPlaceID,
                    draft: session.workPlaceDraft,
                    scheduleImportDraft: session.scheduleImportDraft,
                    initialDefaultRestTime: session.initialDefaultRestTime
                )
            )
            hasSavedChanges = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
            return false
        }
    }
    
    // MARK: 백업
    func restoreEditsIfNeeded() {
        guard session.editingWorkPlaceID != nil else { return }
        guard !hasSavedChanges else { return }
        guard !isAIImportPresented else { return }

        session.workPlaceDraft = originalWorkPlaceDraft
    }
}
