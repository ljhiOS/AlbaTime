//
//  DayScheduleRow.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import SwiftData

struct DayScheduleRow: View {
    let day: String
    let schedule: RegularSchedule?      // 해당 요일의 스케줄 데이터 (없으면 nil)
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
                    Image(systemName: schedule != nil ? "checkmark.square.fill" : "square")
                        .foregroundStyle(schedule != nil ? Color.theme.primary : .gray)
                        .font(.title3)
                    
                    Text(day)
                        .foregroundStyle(schedule != nil ? Color.theme.primary : .gray)
                        .bold()
                }
                .frame(width: 60, alignment: .leading)
            }
            .buttonStyle(.plain) // 버튼 깜빡임 방지
            
            Spacer()
            
            // 2. 시간 설정 (스케줄이 있을 때만 표시)
            if let sch = schedule {
                HStack(spacing: 5) {
                    // 시작 시간 바인딩
                    let startBinding = Binding(
                        get: { sch.startTime },
                        set: { sch.startTime = $0 }
                    )
                    // 종료 시간 바인딩
                    let endBinding = Binding(
                        get: { sch.endTime },
                        set: { sch.endTime = $0 }
                    )
                    
                    DatePicker("", selection: startBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 80)
                    
                    Text("~")
                    
                    DatePicker("", selection: endBinding, displayedComponents: .hourAndMinute)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    // 경고 해결: .modelContainer(container)를 붙여서 container를 사용하게 만듭니다.
    return DayScheduleRow(day: "월", schedule: nil, toggleAction: {})
        .modelContainer(container)
}
