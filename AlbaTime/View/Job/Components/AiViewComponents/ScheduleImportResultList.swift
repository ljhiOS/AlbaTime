//
//  ScheduleImportResultList.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportResultList: View {
    @ObservedObject var sivm: ScheduleImportViewModel
    
    // 키보드가 올라왔을 때 리스트 스크롤을 제어하기 위한 포커스 상태
    @FocusState private var focusedField: String?
    
    var body: some View {
        List {
            // 1. 이미지 미리보기 섹션
            if let image = sivm.selectedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets()) // 여백 제거
                }
            }
            
            // 2. 스케줄 리스트 섹션 (인라인 편집)
            Section {
                if sivm.parsedSchedules.isEmpty {
                    emptyStateView
                } else {
                    // 배열 Binding으로 각 행을 인라인 편집한다.
                    ForEach($sivm.parsedSchedules) { $schedule in
                        InlineEditRow(schedule: $schedule)
                            .focused($focusedField, equals: schedule.id.uuidString)
                    }
                    .onDelete(perform: deleteSchedule) // 스와이프 삭제 지원
                }
            } header: {
                HStack {
                    Text("인식된 스케줄 (\(sivm.parsedSchedules.count)건)")
                    Spacer()
                    // 헤더에 [+] 버튼 배치
                    Button {
                        sivm.addNewSchedule()
                    } label: {
                        Label("추가", systemImage: "plus")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            } footer: {
                if !sivm.parsedSchedules.isEmpty {
                    Text("시간을 터치하여 수정하고, 왼쪽으로 밀어서 삭제하세요.")
                }
            }
        }
        .onTapGesture {
            // 빈 공간 터치 시 키보드 내리기
            focusedField = nil
        }
    }
    
    // MARK: - Actions
    private func deleteSchedule(at offsets: IndexSet) {
        sivm.parsedSchedules.remove(atOffsets: offsets)
    }
    
    // MARK: - Subviews
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("인식된 스케줄이 없습니다.")
                .foregroundStyle(.secondary)
            Text("오른쪽 상단의 '추가' 버튼을 눌러보세요.")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Inline Edit Row
struct InlineEditRow: View {
    @Binding var schedule: ParsedSchedule
    
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
            
            // 2. 시간 입력 (기존 동일)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    DatePicker("", selection: $schedule.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(maxWidth: 90)
                        .scaleEffect(0.9)
                    
                    Text("-")
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 2)
                    
                    DatePicker("", selection: $schedule.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(maxWidth: 90)
                        .scaleEffect(0.9)
                }
                
                if let hours = calculateHours(start: schedule.startTime, end: schedule.endTime) {
                    Text(hours)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.leading, 8)
                }
            }
            
            Spacer()
            
            // 3. 라벨 입력 (기존 동일)
            TextField("라벨", text: Binding(
                get: { schedule.scheduleName ?? "" },
                set: { schedule.scheduleName = $0.isEmpty ? nil : $0 }
            ))
            .font(.caption)
            .multilineTextAlignment(.center)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .frame(width: 60)
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
    
    private func calculateHours(start: Date, end: Date) -> String? {
        var calcEnd = end
        if end < start {
            calcEnd = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
        }
        let diff = calcEnd.timeIntervalSince(start)
        let hours = diff / 3600
        if hours > 0 {
            let value = (hours.truncatingRemainder(dividingBy: 1) == 0) ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
            return "\(value)h"
        }
        return nil
    }
}

#Preview {
    ScheduleImportResultList(sivm: ScheduleImportViewModel())
}
