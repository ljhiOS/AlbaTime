//
//  JobListViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation
import SwiftData

@MainActor
class JobListViewModel: ObservableObject {
    @Published var showDeleteError = false
    @Published var deleteErrorMessage = ""
    
    private let deleteWorkCard = DeleteWorkCard()
    private let toggleWorkplaceAlarm = ToggleWorkplaceAlarm()
    private let toggleWorkplacePin = ToggleWorkplacePin()
    
    func delete(_ workplace: Workplace, context: ModelContext) {
        do {
            try deleteWorkCard.execute(workplace: workplace, context: context)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    @discardableResult
    func toggleAlarm(_ workplace: Workplace, context: ModelContext) -> Bool {
        do {
            try toggleWorkplaceAlarm.execute(workplace: workplace, context: context)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }

    @discardableResult
    func togglePin(_ workplace: Workplace, context: ModelContext) -> Bool {
        do {
            try toggleWorkplacePin.execute(workplace: workplace, context: context)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }
}
