//
//  ScheduleGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct ScheduleGroup: View {
    @ObservedObject var ajvm: AddJobViewModel
    @Environment(\.modelContext) var context
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("요일별 근무 시간")
                    .font(.callout)
                Spacer()
                Button("전체 09-18시 초기화") { withAnimation { ajvm.resetAllDays(context: context) } }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(ajvm.days, id: \.self) { day in
                    DayScheduleRow(
                        day: day,
                        schedule: ajvm.getSchedule(for: day),
                        toggleAction: { ajvm.toggleDay(day, context: context) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, configurations: config)
    
    // 🔥 [수정] type 지정 필수
    let vm = AddJobViewModel(type: .fixed)
    
    // 샘플 데이터 추가
    let monday = RegularSchedule(dayOfWeek: "월", startTime: Date(), endTime: Date())
    monday.workplace = vm.job // 관계 설정도 안전하게 추가
    vm.job.regularSchedules.append(monday)
    
    return ScheduleGroup(ajvm: vm)
        .modelContainer(container)
}
