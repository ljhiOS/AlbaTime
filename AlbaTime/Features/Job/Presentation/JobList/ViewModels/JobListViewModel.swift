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
    private let workPlaceDeleting: any WorkPlaceDeleting
    private let alarmToggling: any WorkPlaceAlarmToggling
    private let pinToggling: any WorkPlacePinToggling
    private let memoUpdating: any WorkPlaceMemoUpdating

    init(
        workPlaceDeleting: any WorkPlaceDeleting,
        alarmToggling: any WorkPlaceAlarmToggling,
        pinToggling: any WorkPlacePinToggling,
        memoUpdating: any WorkPlaceMemoUpdating
    ) {
        self.workPlaceDeleting = workPlaceDeleting
        self.alarmToggling = alarmToggling
        self.pinToggling = pinToggling
        self.memoUpdating = memoUpdating
    }
    
    func delete(workPlaceID: UUID) {
        do {
            try workPlaceDeleting.execute(workPlaceID: workPlaceID)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    @discardableResult
    func toggleAlarm(workPlaceID: UUID) -> Bool {
        do {
            try alarmToggling.execute(workPlaceID: workPlaceID)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }

    @discardableResult
    func togglePin(workPlaceID: UUID) -> Bool {
        do {
            try pinToggling.execute(workPlaceID: workPlaceID)
            return true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
            return false
        }
    }

    func updateMemo(
        workPlaceID: UUID,
        memo: String
    ) {
        do {
            try memoUpdating.execute(workPlaceID: workPlaceID, memo: memo)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}
