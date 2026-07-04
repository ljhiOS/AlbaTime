//
//  ScheduleGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

// 고정 근무 요일/시간 입력 카드.
// 탭은 선택/추가, 롱프레스는 삭제로 역할을 분리한다.
struct ScheduleGroup: View {
    @ObservedObject var ajvm: AddWorkPlaceViewModel
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
        let vm: AddWorkPlaceViewModel

        init() {
            let calendar = Calendar.current
            let today = Date()
            let mondayStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today
            let mondayEnd = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? today
            let wednesdayStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today
            let wednesdayEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today) ?? today

            let seed = WorkPlaceEditingSeed(
                id: UUID(),
                workPlaceDraft: WorkPlaceDraft(
                    name: "알바타임 카페",
                    hourlyWage: 11000,
                    defaultRestTime: 60,
                    defaultMemo: "",
                    taxType: .none,
                    allowanceType: .none,
                    workType: .fixed,
                    targetWeeklyCount: 3,
                    expectedDailyHours: 5,
                    regularSchedules: [
                        RegularScheduleDraft(id: UUID(), dayOfWeek: "월", startTime: mondayStart, endTime: mondayEnd, breakTime: 60),
                        RegularScheduleDraft(id: UUID(), dayOfWeek: "수", startTime: wednesdayStart, endTime: wednesdayEnd, breakTime: 30)
                    ]
                ),
                scheduleImportDraft: .empty(),
                savedAIScheduleItems: [],
                initialDefaultRestTime: 60
            )

            vm = AddWorkPlaceViewModel(editingSeed: seed, workPlaceSaving: PreviewScheduleGroupWorkPlaceSaving())
        }

        var body: some View {
            ScheduleGroup(ajvm: vm)
                .padding()
        }
    }

    return PreviewWrapper()
}

@MainActor
private struct PreviewScheduleGroupWorkPlaceSaving: WorkPlaceSaving {
    func execute(_ command: SaveWorkPlaceCommand) throws { }
}
