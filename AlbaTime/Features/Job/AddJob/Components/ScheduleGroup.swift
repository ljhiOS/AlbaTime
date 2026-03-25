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

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("요일별 근무 시간")
                    .font(.callout)
                Spacer()
                Button("평일 전체 선택") {
                    withAnimation {
                        ajvm.resetAllDays()
                        selectedDay = "월"
                    }
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }

            DaySelectUI(
                state: makeState(),
                send: handle
            )
        }
        .onAppear {
            if selectedDay == nil {
                selectedDay = ajvm.days.first(where: { ajvm.getSchedule(for: $0) != nil })
            }
        }
    }

    private func makeState() -> DaySelectUIState<String> {
        let chips = ajvm.days.map { day in
            DaySelectUIChip(
                id: day,
                title: day,
                hasSchedule: ajvm.getSchedule(for: day) != nil
            )
        }

        let schedule = selectedDay.flatMap { ajvm.getSchedule(for: $0) }

        return DaySelectUIState(
            chips: chips,
            selectedID: selectedDay,
            startTime: schedule?.startTime,
            endTime: schedule?.endTime,
            emptyMessage: "요일을 선택하면 근무 시간을 입력할 수 있어요.",
            addButtonTitle: nil
        )
    }

    private func handle(_ action: DaySelectUIAction<String>) {
        switch action {
        case let .tapDay(day):
            if ajvm.getSchedule(for: day) != nil {
                selectedDay = day
            } else {
                ajvm.toggleDay(day)
                selectedDay = day
            }

        case let .longPressDay(day):
            guard ajvm.getSchedule(for: day) != nil else { return }
            Haptics.impact(.medium)
            ajvm.toggleDay(day)

            if selectedDay == day {
                selectedDay = ajvm.days.first(where: { ajvm.getSchedule(for: $0) != nil })
            }

        case .tapAdd:
            break

        case let .changeStartTime(newValue):
            guard let selectedDay else { return }
            ajvm.updateStartTime(for: selectedDay, to: newValue)

        case let .changeEndTime(newValue):
            guard let selectedDay else { return }
            ajvm.updateEndTime(for: selectedDay, to: newValue)
        }
    }
}

#Preview("고정 근무 스케줄 입력") {
    struct PreviewWrapper: View {
        let container: ModelContainer
        let vm: AddJobViewModel

        init() {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: Workplace.self,
                RegularSchedule.self,
                configurations: config
            )

            let calendar = Calendar.current
            let today = Date()

            let defaultStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
            let defaultEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today

            let mondayStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today
            let mondayEnd = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? today

            let wednesdayStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today
            let wednesdayEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today) ?? today

            let job = Workplace(
                name: "알바타임 카페",
                hourlyWage: 11000,
                defaultDays: "월,수",
                defaultStartTime: defaultStart,
                defaultEndTime: defaultEnd,
                defaultRestTime: 60,
                workType: .fixed
            )

            let monday = RegularSchedule(
                dayOfWeek: "월",
                startTime: mondayStart,
                endTime: mondayEnd,
                breakTime: 60
            )

            let wednesday = RegularSchedule(
                dayOfWeek: "수",
                startTime: wednesdayStart,
                endTime: wednesdayEnd,
                breakTime: 30
            )

            monday.workplace = job
            wednesday.workplace = job
            job.regularSchedules.append(contentsOf: [monday, wednesday])

            container.mainContext.insert(job)
            container.mainContext.insert(monday)
            container.mainContext.insert(wednesday)

            vm = AddJobViewModel(editingJob: job)
        }

        var body: some View {
            ScheduleGroup(ajvm: vm)
                .padding()
                .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

