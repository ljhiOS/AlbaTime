//
//  RealAchiveRecordViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import Foundation
import SwiftData
import SwiftUI

class RealAchiveRecordViewModel: ObservableObject {
    
    // 뷰와 연동될 상태 변수들
    @Published var isAdding: Bool = false
    @Published var selectedDate: Date = Date()
    @Published var amountString: String = ""
        
    // MARK: - Logic Functions
        
    /// 기록 추가 또는 수정 로직
    func addRecord(context: ModelContext, existingRecords: [MonthlyRecord]) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
            
        // 1. 이미 같은 연/월 기록이 있는지 확인 (중복 방지)
        if let existRecord = existingRecords.first(where: { $0.year == year && $0.month == month }) {
            // 있으면 금액만 업데이트 (덮어쓰기)
            existRecord.actualAmount = amountString
            print("📝 기존 기록 수정 완료: \(year)년 \(month)월")
        } else {
            // 없으면 새로 생성
            let newRecord = MonthlyRecord(year: year, month: month, actualAmount: amountString)
            context.insert(newRecord)
            print("✨ 새 기록 추가 완료: \(year)년 \(month)월")
        }
            
        // 2. 입력창 닫기 및 초기화
        isAdding = false
        resetForm()
    }
        
    /// 기록 삭제 로직
    func deleteRecord(at offsets: IndexSet, context: ModelContext, sortedRecords: [MonthlyRecord]) {
        for index in offsets {
            let recordToDelete = sortedRecords[index]
            context.delete(recordToDelete)
        }
    }
        
    /// 입력 폼 초기화 (플러스 버튼 누를 때 사용)
    func resetForm() {
        selectedDate = Date()
        amountString = ""
    }
}
