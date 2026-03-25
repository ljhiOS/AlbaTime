//
//  DayCell.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI
import SwiftData

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let todayJobs: [Workplace]
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? Color.theme.primary : Color.theme.textPrimary)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.theme.primary.opacity(0.1) : Color.clear)
                .clipShape(Circle())
            
            if !todayJobs.isEmpty {
                Circle()
                    .fill(Color.theme.primary)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        } //:VStack
    }
}

#Preview("선택됨 + 근무 있음") {
    let today = Date()
    let calendar = Calendar.current

    let sampleJob = Workplace(
        name: "알바타임 카페",
        hourlyWage: 11000,
        defaultDays: "월,수,금",
        defaultStartTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
        defaultEndTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
    )

    return DayCell(
        date: today,
        isSelected: true,
        todayJobs: [sampleJob]
    )
    .padding()
}

#Preview("선택 안 됨 + 근무 있음") {
    let today = Date()
    let calendar = Calendar.current

    let sampleJob = Workplace(
        name: "알바타임 카페",
        hourlyWage: 11000,
        defaultDays: "월,수,금",
        defaultStartTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
        defaultEndTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
    )

    return DayCell(
        date: today,
        isSelected: false,
        todayJobs: [sampleJob]
    )
    .padding()
}

#Preview("선택 안 됨 + 근무 없음") {
    DayCell(
        date: Date(),
        isSelected: false,
        todayJobs: []
    )
    .padding()
}
