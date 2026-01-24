//
//  CalendarView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @StateObject private var cvm = CalendarViewModel()
    @Query var workplaces: [Workplace] // 데이터베이스 감지
    
    let weekDays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 상단 헤더
            HStack {
                Text("캘린더")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                Spacer()
            }
            
            // 월 이동 버튼
            HStack {
                Button(action: { cvm.changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left").foregroundColor(.black)
                }
                
                Spacer()
                Text(cvm.currentMonth.format("yyyy년 M월"))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: { cvm.changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right").foregroundColor(.black)
                }
            }
            .padding()
            
            // 요일 표시
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 10)
            .padding(.horizontal)
            
            // 달력 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
                let days = cvm.generateDaysInMonth()
                
                ForEach(0..<days.count, id: \.self) { index in
                    if let day = days[index] {
                        let jobsOnThisDay = cvm.getScheduledWorkplaces(for: day, allWorkplaces: workplaces)
                        
                        DayCell(
                            date: day,
                            isSelected: cvm.selectedDate.isSameDay(as: day),
                            todayJobs: jobsOnThisDay
                        )
                        .onTapGesture {
                            cvm.selectedDate = day
                        }
                    } else {
                        Text("")
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        
            // 하단 상세 카드
            ScheduleDetailCard(cvm: cvm, allWorkplaces: workplaces)
        }
        .background(Color.white)
        .onAppear { cvm.updateCache(workplaces: workplaces) }
        .onChange(of: workplaces) { _, newValue in cvm.updateCache(workplaces: newValue) }
        .onChange(of: cvm.currentMonth) { _, _ in cvm.updateCache(workplaces: workplaces) }
    }
}
#Preview() {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    let starbucks = Workplace(
        name: "스타벅스",
        hourlyWage: 10300,
        defaultDays: "월/화/수/목/금/토/일",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        defaultRestTime: 60
    )
    container.mainContext.insert(starbucks)
    
    return CalendarView()
        .modelContainer(container)
}
