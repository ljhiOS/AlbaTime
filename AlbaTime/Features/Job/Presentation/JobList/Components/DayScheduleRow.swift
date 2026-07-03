//
//  DayScheduleRow.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI

// TODO: delete components

struct DayScheduleRow: View {
    let day: String
    let isScheduled: Bool
    let startTime: Binding<Date>?
    let endTime: Binding<Date>?
    let toggleAction: () -> Void        // 체크박스 눌렀을 때 실행할 함수
    
    var body: some View {
        HStack {
            // 1. 체크박스 (활성화/비활성화)
            Button {
                withAnimation {
                    toggleAction()
                }
            } label: {
                HStack {
                    Image(systemName: isScheduled ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isScheduled ? Color.theme.primary : .gray)
                        .font(.title3)
                    
                    Text(day)
                        .foregroundStyle(isScheduled ? Color.theme.primary : .gray)
                        .bold()
                }
                .frame(width: 60, alignment: .leading)
            }
            .buttonStyle(.plain) // 버튼 깜빡임 방지
            
            Spacer()
            
            // 2. 시간 설정 (스케줄이 있을 때만 표시)
            if let startTime, let endTime {
                HStack(spacing: 5) {
                    DatePicker("", selection: startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 80)
                    
                    Text("~")
                    
                    DatePicker("", selection: endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 80)
                }
            } else {
                Text("휴무")
                    .font(.subheadline)
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding(12)
        .background(Color.theme.surface)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    DayScheduleRow(
        day: "월",
        isScheduled: false,
        startTime: nil,
        endTime: nil,
        toggleAction: {}
    )
}
