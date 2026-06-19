//
//  InlineEditRow.swift
//  AlbaTime
//
//  Created by 이준희 on 3/14/26.
//

import SwiftUI

struct InlineEditRow: View {
    @Binding var schedule: ScheduleDraftItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            
            // 1. 요일 표시 (Menu로 변경하여 수정 가능하게 함)
            Menu {
                // 현재 날짜가 포함된 주(Week)의 월~일 날짜 목록 생성
                ForEach(getDaysInSameWeek(as: schedule.date), id: \.self) { date in
                    Button {
                        updateDate(newDate: date)
                    } label: {
                        HStack {
                            Text(formatDateFull(date)) // "1/20 (월)"
                            if Calendar.current.isDate(date, inSameDayAs: schedule.date) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                // 기존 디자인 유지 (터치 가능한 버튼 역할)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isWeekend(schedule.date) ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    VStack(spacing: 0) {
                        Text(formatWeekday(schedule.date))
                            .font(.headline)
                            .bold()
                            .foregroundStyle(isWeekend(schedule.date) ? .red : .primary)
                    }
                }
            }
            // 리스트 행 터치 간섭 방지 (iOS 버전에 따라 필요할 수 있음)
            .buttonStyle(.borderless)
            .frame(width: 64)
            
            // 2. 시간 입력 (기존 동일)
            HStack(spacing: 0) {
                DatePicker("", selection: $schedule.startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(maxWidth: 90)
                    .scaleEffect(0.9)
                
                Text("~")
                    .foregroundStyle(Color.theme.textSecondary)
                    .padding(.horizontal, 2)
                
                DatePicker("", selection: $schedule.endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(maxWidth: 90)
                    .scaleEffect(0.9)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // 3. 라벨 입력 (기존 동일)
            TextField("라벨", text: Binding(
                get: { schedule.memo ?? "" },
                set: { schedule.memo = $0.isEmpty ? nil : $0 }
            ))
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)
            .frame(width: 44, height: 44)
            .background(Color.theme.field)
            .cornerRadius(6)
            .frame(width: 64)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Logic Helpers
    
    // 날짜가 변경되면 startTime과 endTime의 날짜(년/월/일)도 같이 이동시켜야 함
    private func updateDate(newDate: Date) {
        let calendar = Calendar.current
        
        // 1. 메인 날짜 변경
        schedule.date = newDate
        
        // 2. 시작/종료 시간의 '날짜' 부분도 newDate로 동기화 (시간은 유지)
        schedule.startTime = combineDateAndTime(date: newDate, time: schedule.startTime)
        
        // 종료 시간 동기화 (만약 종료시간이 시작시간보다 빠르면 다음날로 처리 유지)
        var newEndTime = combineDateAndTime(date: newDate, time: schedule.endTime)
        if newEndTime < schedule.startTime {
            newEndTime = calendar.date(byAdding: .day, value: 1, to: newEndTime) ?? newEndTime
        }
        schedule.endTime = newEndTime
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
    }
    
    // 현재 날짜가 속한 주의 월~일 날짜 배열 반환
    private func getDaysInSameWeek(as date: Date) -> [Date] {
        let calendar = Calendar.current
        // 해당 주의 시작일(일요일 또는 월요일) 구하기
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [date] }
        
        var days: [Date] = []
        // 주간 7일 생성
        for i in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(d)
            }
        }
        return days
    }
    
    // MARK: - Format Helpers
    
    private func formatWeekday(_ date: Date) -> String {
        return date.koreanWeekday
    }
    
    private func formatDateFull(_ date: Date) -> String {
        return date.monthDayWeekdayText // 예: 1/20 (월)
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let w = Calendar.current.component(.weekday, from: date)
        return w == 1 || w == 7
    }
}

#Preview("Inline Edit Row") {
    struct PreviewWrapper: View {
        @State private var schedule: ScheduleDraftItem = {
            let calendar = Calendar.current
            let base = calendar.startOfDay(for: Date())
            let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
            let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: base) ?? base

            return ScheduleDraftItem(
                id: UUID(),
                date: base,
                startTime: start,
                endTime: end,
                breakTime: 0,
                memo: "오픈",
                source: .aiImport
            )
        }()

        var body: some View {
            InlineEditRow(schedule: $schedule)
                .padding()
                .background(Color.theme.surface)
        }
    }

    return PreviewWrapper()
}
