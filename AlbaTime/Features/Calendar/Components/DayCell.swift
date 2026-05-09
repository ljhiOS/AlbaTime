//
//  DayCell.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasWork: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? Color.theme.primary : Color.theme.textPrimary)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.theme.primary.opacity(0.1) : Color.clear)
                .clipShape(Circle())
            
            if hasWork {
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

    return DayCell(
        date: today,
        isSelected: true,
        hasWork: true
    )
    .padding()
}

#Preview("선택 안 됨 + 근무 있음") {
    let today = Date()

    return DayCell(
        date: today,
        isSelected: false,
        hasWork: true
    )
    .padding()
}

#Preview("선택 안 됨 + 근무 없음") {
    DayCell(
        date: Date(),
        isSelected: false,
        hasWork: false
    )
    .padding()
}
