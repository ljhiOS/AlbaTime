//
//  ScheduleGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData
import UIKit

// TODO: 각 요일별 휴게시간 설정 할지 말지 고민 필요
// 장점: 각 요일별로 휴게시간 입력하여 휴게시간이 요일별로 다른 사용자에게 편리함을 제공(특히 자율 근무제 사용자)
// 단점: 근무지 만들때 불편함이나 귀찮음이 많아짐

// 고정 근무 요일/시간 입력 카드.
// 탭은 선택/추가, 롱프레스는 삭제로 역할을 분리한다.
struct ScheduleGroup: View {
    @ObservedObject var ajvm: AddJobViewModel
    @Environment(\.modelContext) var context
    @State private var selectedDay: String?
//    @State private var choiceBreakTimeType: Bool = false
    
    private let twentyFourHourLocale = Locale(identifier: "ko_KR@hc=h23")
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("요일별 근무 시간")
                    .font(.callout)
                Spacer()
                Button("평일 전체 선택") {
                    withAnimation {
                        ajvm.resetAllDays(context: context)
                        selectedDay = "월"
                    }
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("요일 선택")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(ajvm.days, id: \.self) { day in
                        let hasSchedule = ajvm.getSchedule(for: day) != nil // Bool
                        let isSelected = selectedDay == day // Bool

                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : (hasSchedule ? Color.theme.primary : .primary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                isSelected
                                ? Color.theme.primary
                                : (hasSchedule ? Color.theme.primary.opacity(0.15) : Color.theme.surface)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                handleDayTap(day)
                            }
                            .onLongPressGesture(minimumDuration: 0.25) {
                                handleDayLongPress(day)
                            }
                    }
                }

                if let current = selectedSchedule {
                    HStack {
                        DatePicker("", selection: startBinding(for: current), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, twentyFourHourLocale)

                        Text("~")
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: endBinding(for: current), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, twentyFourHourLocale)

                        Spacer()
                    }
                    
                    Text("삭제를 원하면 요일 버튼을 길게 눌러주세요.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("요일을 선택하면 근무 시간을 입력할 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(Color.theme.field)
            .cornerRadius(8)
        }
        .onAppear {
            if selectedDay == nil {
                selectedDay = ajvm.days.first(where: { ajvm.getSchedule(for: $0) != nil })
            }
        }
    }

    private var selectedSchedule: RegularSchedule? {
        guard let selectedDay else { return nil }
        return ajvm.getSchedule(for: selectedDay)
    }

    // 요일 탭: 이미 존재하면 선택, 없으면 생성 후 선택.
    private func handleDayTap(_ day: String) {
        let hasSchedule = ajvm.getSchedule(for: day) != nil

        if hasSchedule {
            selectedDay = day
        } else {
            ajvm.toggleDay(day, context: context)
            selectedDay = day
        }
    }

    // 요일 롱프레스: 해당 요일 스케줄 삭제 + 햅틱.
    private func handleDayLongPress(_ day: String) {
        let hasSchedule = ajvm.getSchedule(for: day) != nil
        guard hasSchedule else { return }

        Haptics.impact(.medium)

        ajvm.toggleDay(day, context: context)
        if selectedDay == day {
            selectedDay = ajvm.days.first(where: { ajvm.getSchedule(for: $0) != nil })
        }
    }

    // 선택 요일의 시작 시간을 직접 바인딩한다.
    private func startBinding(for schedule: RegularSchedule) -> Binding<Date> {
        Binding(
            get: { schedule.startTime },
            set: { schedule.startTime = $0 }
        )
    }

    // 선택 요일의 종료 시간을 직접 바인딩한다.
    private func endBinding(for schedule: RegularSchedule) -> Binding<Date> {
        Binding(
            get: { schedule.endTime },
            set: { schedule.endTime = $0 }
        )
    }
//    
//    private func breakTimeBinding(for schedule: RegularSchedule) -> Binding<Int> {
//        Binding(
//            get: { schedule.breakTime },
//            set: { schedule.breakTime = max(0, $0) }
//        )
//    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, configurations: config)
    
    // 프리뷰용 고정 근무 타입
    let vm = AddJobViewModel(type: .fixed)
    
    // 샘플 데이터 추가
    let monday = RegularSchedule(dayOfWeek: "월", startTime: Date(), endTime: Date())
    monday.workplace = vm.job // 관계 설정도 안전하게 추가
    vm.job.regularSchedules.append(monday)
    
    return ScheduleGroup(ajvm: vm)
        .modelContainer(container)
}
