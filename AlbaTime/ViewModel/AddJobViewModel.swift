//
//  AddJobViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation
import SwiftData
import SwiftUI

class AddJobViewModel: ObservableObject {
    @Published var placeName: String = ""
    @Published var wage: String = ""
    @Published var selectedDate: Set<String> = []
    
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        @Published var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    
    @Published var memo: String = ""
    @Published var restTime: String = ""
//    @Published var allTime: String = ""
    
    @Published var taxType: TaxType = .none
    
    func toggleDay(_ day: String) {
        if selectedDate.contains(day) {
            selectedDate.remove(day)
        } else {
            selectedDate.insert(day)
        }
    }
    
    func saveJob(context: SwiftData.ModelContext) {
        print("saveJob CALLED")
        print("Saving placeName: \(placeName), Wage: \(wage), SelectedDate: \(selectedDate), StartTime: \(startTime), EndTime: \(endTime), restTime: \(restTime), memo: \(memo), taxType: \(taxType)")
        
        // 월화수목금 정렬을 위한 딕셔너리
        let dayOrder: [String: Int] = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        
        let sortedDays = selectedDate.sorted {
            (dayOrder[$0] ?? 99) < (dayOrder[$1] ?? 99) // dayOrder 없는 예외값은 99로 보내서 맨 뒤로 보냄
        }
        let dayString = sortedDays.joined(separator: "/")
        // 여기까지
        
        let hourWage = Int(wage) ?? 0
        let rest = Int(restTime) ?? 0
        
        if hourWage <= 0 {
            print("시급 요건에 맞지 않는 형식입니다")
        }
        
        if dayString.isEmpty {
            print("일 할 날짜 선택 X")
        }
        
        let newWorkplace = Workplace(
            name: self.placeName,
            hourlyWage: hourWage,
            defaultDays: dayString,
            defaultStartTime: self.startTime,
            defaultEndTime: self.endTime,
//            allTimes: self.allTime
            defaultRestTime: rest,
            defaultMemo: self.memo,
            taxType: self.taxType
        )
        
        context.insert(newWorkplace)
        print("근무지 저장완료: \(newWorkplace.name)")
        
        // 근무 시작 전 알람
        NotificationManager.shared.scheduleWorkNotification(for: newWorkplace)
    }
}

