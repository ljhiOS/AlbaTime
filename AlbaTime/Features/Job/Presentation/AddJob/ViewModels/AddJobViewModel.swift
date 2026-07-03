//
//  AddJobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Combine
import Foundation

@MainActor
class AddJobViewModel: ObservableObject {
    var session: JobEditingSession
    
    @Published var isAIImportPresented: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    private let initialJobDraft: JobDraft
    
    // 실제 저장 UseCase는 Route/Composition에서 주입됩니다.
    private let jobSaving: any JobSaving
    private var hasSavedChanges: Bool = false
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    // MARK: - 초기화 (Init)
    
    // 신규 생성 모드
    init(type: WorkType, jobSaving: any JobSaving) {
        let seed = JobEditingSeed.new(type: type)
        self.session = JobEditingSession(seed: seed)
        self.initialJobDraft = seed.jobDraft
        self.jobSaving = jobSaving
    }
    
    // 수정 모드
    init(editingSeed: JobEditingSeed, jobSaving: any JobSaving) {
        self.session = JobEditingSession(seed: editingSeed, editingJobID: editingSeed.id)
        self.initialJobDraft = editingSeed.jobDraft
        self.jobSaving = jobSaving
    }
    
    // MARK: - 유효성 검사 및 AI
    // TODO: 저장 검증과 AI 진입 전 기본 검증의 중복 조건 정리 검토
    func validateAndOpenAI() {
        if session.jobDraft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "매장명을 입력해주세요."
            showAlert = true
            return
        }
        
        if session.jobDraft.hourlyWage <= 0 {
            errorMessage = "올바른 시급을 입력해주세요."
            showAlert = true
            return
        }
        isAIImportPresented = true
    }
    
    // MARK: - 요일별 스케줄 로직
    
    func getSchedule(for day: String) -> RegularScheduleDraft? {
        session.jobDraft.regularSchedules.first { $0.dayOfWeek == day }
    }
    
    // MARK: 스케줄 선택 및 취소
    func updateStartTime(for day: String, to newValue: Date) {
        guard let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.jobDraft.regularSchedules[index].startTime = newValue
    }
    
    func updateEndTime(for day: String, to newValue: Date) {
        guard let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) else { return }
        session.jobDraft.regularSchedules[index].endTime = newValue
    }

    func toggleDay(_ day: String) {
        if let index = session.jobDraft.regularSchedules.firstIndex(where: { $0.dayOfWeek == day }) {
            session.jobDraft.regularSchedules.remove(at: index)
        } else {
            let newSchedule = RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.jobDraft.defaultRestTime
            )
            session.jobDraft.regularSchedules.append(newSchedule)
        }
    }

    func resetAllDays() {
        let weekdays = ["월", "화", "수", "목", "금"]
        
        session.jobDraft.regularSchedules = weekdays.map { day in
            RegularScheduleDraft(
                id: UUID(),
                dayOfWeek: day,
                startTime: Date.makeTime(9, 0),
                endTime: Date.makeTime(18, 0),
                breakTime: session.jobDraft.defaultRestTime
            )
        }
    }
    
    // MARK: 저장
    func save() -> Bool {
        do {
            try jobSaving.execute(
                .jobDraft(
                    editingJobID: session.editingJobID,
                    draft: session.jobDraft,
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
        guard session.editingJobID != nil else { return }
        guard !hasSavedChanges else { return }
        guard !isAIImportPresented else { return }

        session.jobDraft = initialJobDraft
    }
}
