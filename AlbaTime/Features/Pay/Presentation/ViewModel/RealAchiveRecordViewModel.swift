//
//  RealAchiveRecordViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import Foundation

@MainActor
class RealAchiveRecordViewModel: ObservableObject {

    // 뷰와 연동될 상태 변수들
    @Published var isAdding: Bool = false
    @Published var selectedDate: Date = Date()
    @Published var amountString: String = ""

    private let monthlyRecordSaving: any MonthlyRecordSaving
    private let monthlyRecordDeleting: any MonthlyRecordDeleting

    private let analyticsTracker: any AnalyticsTracking

    init(
        monthlyRecordSaving: any MonthlyRecordSaving,
        monthlyRecordDeleting: any MonthlyRecordDeleting,
        analyticsTracker: any AnalyticsTracking
    ) {
        self.monthlyRecordSaving = monthlyRecordSaving
        self.monthlyRecordDeleting = monthlyRecordDeleting
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - Logic Functions

    /// 기록 추가 또는 수정 로직
    func addRecord(existingRecords: [MonthlyRecord]) {
        do {
            try monthlyRecordSaving.execute(
                selectedDate: selectedDate,
                amountString: amountString,
                existingRecords: existingRecords
            )
            analyticsTracker.track(.monthlyIncomeSaved)
            isAdding = false
            resetForm()
        } catch {
            print(error.localizedDescription)
        }
    }

    /// 기록 삭제 로직
    func deleteRecord(at offsets: IndexSet, sortedRecords: [MonthlyRecord]) {
        do {
            try monthlyRecordDeleting.execute(
                offsets: offsets,
                sortedRecords: sortedRecords
            )
        } catch {
            print(error.localizedDescription)
        }
    }

    /// 입력 폼 초기화 (플러스 버튼 누를 때 사용)
    func resetForm() {
        selectedDate = Date()
        amountString = ""
    }
}
