//
//  RealAchiveRecordViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class RealAchiveRecordViewModel: ObservableObject {
    
    // 뷰와 연동될 상태 변수들
    @Published var isAdding: Bool = false
    @Published var selectedDate: Date = Date()
    @Published var amountString: String = ""

    private let saveMonthlyRecord = SaveMonthlyRecord()
    private let deleteMonthlyRecord = DeleteMonthlyRecord()

    // MARK: - Logic Functions

    /// 기록 추가 또는 수정 로직
    func addRecord(context: ModelContext, existingRecords: [MonthlyRecord]) {
        do {
            try saveMonthlyRecord.execute(
                selectedDate: selectedDate,
                amountString: amountString,
                existingRecords: existingRecords,
                context: context
            )
            isAdding = false
            resetForm()
        } catch {
            print(error.localizedDescription)
        }
    }

    /// 기록 삭제 로직
    func deleteRecord(at offsets: IndexSet, context: ModelContext, sortedRecords: [MonthlyRecord]) {
        do {
            try deleteMonthlyRecord.execute(
                offsets: offsets,
                sortedRecords: sortedRecords,
                context: context
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
