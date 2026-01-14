    //
    //  CalendarView.swift
    //  AlbaTime
    //
    //  Created by 이준희 on 12/8/25.

import SwiftUI
import SwiftData

struct CalendarView: View {
    @StateObject private var cvm = CalendarViewModel()
    
    @Query var workplaces: [Workplace]
    
    let weekDays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Text("캘린더")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                Spacer()
            }
            
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
            } //:HStack
            .padding()
            
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            } //:HStack
            .padding(.bottom, 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
                ForEach(0..<cvm.generateDaysInMonth().count, id: \.self) { index in
                    let day = cvm.generateDaysInMonth()[index]
                    
                    if let day = day {
                        let jobsOnThisDay = cvm.getScheduledWorkplaces(for: day, allWorkplaces: workplaces)
                        
                        DayCell(
                            date: day,
                            isSelected: cvm.selectedDate.isSameDay(as: day),
                            todayJobs: jobsOnThisDay //
                        )
                        .onTapGesture {
                            cvm.selectedDate = day
                        }
                    } else {
                        Text("")
                    }
                } //:loop
            } //:LazyGrid
            .padding(.horizontal)
            
            Spacer()
        
            ScheduleDetailCard(cvm: cvm, allWorkplaces: workplaces)
        }
        .background(Color.white)
    }
}
// 데이터 없을 때 프리뷰
#Preview("데이터 없음") {
    CalendarView()
}
// 데이터 있을때 프리뷰
#Preview("데이터 있음") {
    // 1. 프리뷰용 가상 데이터베이스(컨테이너) 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    // 2. 가짜 데이터 생성
    // 꿀팁: 프리뷰를 언제 켜도 데이터가 보이게 하려면, 모든 요일("월/화/수/목/금/토/일")을 다 넣은 알바를 하나 만듭니다.
    let starbucks = Workplace(
        name: "스타벅스",
        hourlyWage: 10300,
        defaultDays: "월/화/수/목/금/토/일", // 무조건 오늘 날짜에 걸리게 함
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        defaultRestTime: 60
    )
    
    let gs25 = Workplace(
        name: "GS25 (월수금)",
        hourlyWage: 9860,
        defaultDays: "월/수/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
    )
    
    // 3. 데이터베이스에 넣기
    container.mainContext.insert(starbucks)
    container.mainContext.insert(gs25)
    
    // 4. 뷰에 컨테이너 주입해서 리턴
    return CalendarView()
        .modelContainer(container)
}
    
