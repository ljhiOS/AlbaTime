//
//  JobListViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation

@MainActor
class JobListViewModel: ObservableObject {
    @Published var showDeleteError = false
    @Published var deleteErrorMessage = ""
    
    // 실제 UseCase는 Route/Composition에서 주입됩니다.
    private let workplaceDeleting: any WorkplaceDeleting
    private let alarmToggling: any WorkplaceAlarmToggling
    private let pinToggling: any WorkplacePinToggling
    private let memoUpdating: any WorkplaceMemoUpdating

    init(
        workplaceDeleting: any WorkplaceDeleting,
        alarmToggling: any WorkplaceAlarmToggling,
        pinToggling: any WorkplacePinToggling,
        memoUpdating: any WorkplaceMemoUpdating
    ) {
        self.workplaceDeleting = workplaceDeleting
        self.alarmToggling = alarmToggling
        self.pinToggling = pinToggling
        self.memoUpdating = memoUpdating
    }
    
    func delete(workplaceID: UUID) {
        do {
            try workplaceDeleting.execute(workplaceID: workplaceID)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    @discardableResult
    func toggleAlarm(workplaceID: UUID) -> Bool {
        do {
            try alarmToggling.execute(workplaceID: workplaceID)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }

    @discardableResult
    func togglePin(workplaceID: UUID) -> Bool {
        do {
            try pinToggling.execute(workplaceID: workplaceID)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }

    func updateMemo(
        workplaceID: UUID,
        memo: String
    ) {
        do {
            try memoUpdating.execute(workplaceID: workplaceID, memo: memo)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}
