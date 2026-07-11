//
//  ScheduleDetailCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI

struct ScheduleDetailCard: View {
    let selectedDate: Date
    let schedules: [CalendarScheduleState]
    let totalPay: Int
    let onSaveTime: (CalendarScheduleState, Date, Date) -> Void

    @State private var editingSchedule: CalendarScheduleState?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 헤더 영역 (날짜 + 총 급여)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.format("M월 d일 (E)"))
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if schedules.isEmpty {
                        Text("예정된 근무가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("총 \(schedules.count)개의 알바")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if !schedules.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₩\(totalPay.formatted())")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("선택한 날짜의 예상 급여")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider()
            
            // 본문 영역 (리스트 or 빈 화면)
            if schedules.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("오늘은 쉬는 날이에요!")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(schedules) { schedule in
                            Button {
                                editingSchedule = schedule
                            } label: {
                                WorkPlaceComponent(schedule: schedule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxHeight: 250)
            }
        }
        .padding(24)
        .background(Color.theme.field)
        .cornerRadius(12, antialiased: true)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
        .sheet(item: $editingSchedule) { schedule in
            WorkTimeEditorSheet(schedule: schedule, onSave: onSaveTime)
        }
    }
}

private struct WorkTimeEditorSheet: View {
    let schedule: CalendarScheduleState
    let onSave: (CalendarScheduleState, Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startTime: Date
    @State private var endTime: Date

    init(
        schedule: CalendarScheduleState,
        onSave: @escaping (CalendarScheduleState, Date, Date) -> Void
    ) {
        self.schedule = schedule
        self.onSave = onSave
        _startTime = State(initialValue: schedule.startTime)
        _endTime = State(initialValue: schedule.endTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("시작 시간", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("종료 시간", selection: $endTime, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("근무 시간 조정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("취소")
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(schedule, startTime, endTime)
                        dismiss()
                    } label: {
                        Text("저장")
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                }
            }
        }
        .presentationDetents([.height(240)])
    }
}

// MARK: - Preview

#Preview("근무 있음") {
    let today = Date()
    let schedules = [
        CalendarScheduleState(
            id: UUID(),
            workPlaceID: UUID(),
            workPlaceName: "GS25 강남점",
            date: today,
            startTime: today,
            endTime: today.addingTimeInterval(5 * 60 * 60),
            breakTime: 0,
            estimatedPay: 44370,
            hourlyWage: 9860
        ),
        CalendarScheduleState(
            id: UUID(),
            workPlaceID: UUID(),
            workPlaceName: "스타벅스",
            date: today,
            startTime: today.addingTimeInterval(9 * 60 * 60),
            endTime: today.addingTimeInterval(13 * 60 * 60),
            breakTime: 0,
            estimatedPay: 44000,
            hourlyWage: 11000
        )
    ]
    
    return ZStack {
        Color.black // 배경색 확인용
        
        ScheduleDetailCard(
            selectedDate: today,
            schedules: schedules,
            totalPay: schedules.map(\.estimatedPay).reduce(0, +),
            onSaveTime: { _, _, _ in }
        )
    }
}

#Preview("근무 없음 (빈 상태)") {
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ScheduleDetailCard(
            selectedDate: Date(),
            schedules: [],
            totalPay: 0,
            onSaveTime: { _, _, _ in }
        )
    }
}
