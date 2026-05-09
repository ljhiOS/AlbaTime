//
//  JobEditingSession.swift
//  AlbaTime
//
//  Created by 이준희 on 3/26/26.
//

import Foundation

@MainActor
final class JobEditingSession: ObservableObject {
    @Published var jobDraft: JobDraft
    @Published var scheduleImportDraft: ScheduleImportDraft
    
    let editingJob: Workplace?
    
    init(type: WorkType) {
        self.editingJob = nil
        self.jobDraft = .makeNew(type: type)
        self.scheduleImportDraft = .empty()
    }
    
    init(editingJob: Workplace) {
        self.editingJob = editingJob
        self.jobDraft = .from(editingJob)
        self.scheduleImportDraft = .from(editingJob)
    }
}
